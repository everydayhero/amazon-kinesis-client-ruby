require 'base64'
require 'logger'
require 'aws/kclrb'

module Kcl
  class AdvancedRecordProcessor
    include RecordProcessor
    LOG = Logger.new STDERR

    DEFAULT_SLEEP_SECONDS = 5
    DEFAULT_CHECKPOINT_RETRIES = 5
    DEFAULT_CHECKPOINT_FREQ_SECONDS = 60

    def initialize sleep_seconds: DEFAULT_SLEEP_SECONDS,
                   checkpoint_retries: DEFAULT_CHECKPOINT_RETRIES,
                   checkpoint_freq_seconds: DEFAULT_CHECKPOINT_FREQ_SECONDS
      @sleep_seconds = sleep_seconds
      @checkpoint_retries = checkpoint_retries
      @checkpoint_freq_seconds = checkpoint_freq_seconds
    end

    def process_record _record; end

    def init shard_id
      LOG.info "Start consumming at shard: #{shard_id}"
      self.largest_seq = nil
      # So that first records through would update the checkpoint
      self.last_checkpoint_time = Time.at(0)
    end

    def process_records records, checkpointer
      records.each { |record| handle_record record }
    rescue => error
      LOG.error "Encountered an exception while processing records. Exception was #{error}"
      force_checkpoint = true
    ensure
      if (Time.now - last_checkpoint_time > checkpoint_freq_seconds) || force_checkpoint
        checkpoint checkpointer
        self.last_checkpoint_time = Time.now
      end
    end

    def shutdown checkpointer, reason
      if reason == 'TERMINATE'
        LOG.info 'Was told to terminate, will attempt to checkpoint.'
        checkpoint checkpointer, sequence_number: nil
      else
        LOG.info 'Shutting down due to failover. Will not checkpoint.'
      end
    end

    private

    attr_accessor :largest_seq, :last_checkpoint_time

    attr_reader :sleep_seconds, :checkpoint_retries, :checkpoint_freq_seconds

    def handle_record record
      data = Base64.decode64 record['data']
      seq = record['sequenceNumber'].to_i
      key = record['partitionKey']

      process_record data: data, partition_key: key, sequence_number: seq

      self.largest_seq = seq if largest_seq.nil? || seq > largest_seq
    end

    def checkpoint checkpointer, sequence_number: largest_seq
      checkpoint_retries.times do |try_count|
        break if try_checkpoint checkpointer, sequence_number, try_count

        sleep sleep_seconds
      end
    end

    # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity
    def try_checkpoint checkpointer, sequence_number, try_count
      seq = sequence_number.to_s if sequence_number
      checkpointer.checkpoint seq

      true
    rescue Aws::KCLrb::CheckpointError => checkpoint_error
      case checkpoint_error.to_s
      when 'ShutdownException'
        LOG.info 'Encountered shutdown execption, skipping checkpoint'
        true
      when 'ThrottlingException'
        if checkpoint_retries - 1 == try_count
          LOG.error "Failed to checkpoint after #{try_count} attempts, giving up."
          true
        else
          LOG.info "Was throttled while checkpointing, will attempt again in #{sleep_seconds} seconds"
          false
        end
      when 'InvalidStateException'
        LOG.error "MultiLangDaemon reported an invalid state while checkpointing."
        false
      else
        LOG.error "Encountered an error while checkpointing, error was #{checkpoint_error}."
        false
      end
    end
    # rubocop:enable Metrics/MethodLength,Metrics/CyclomaticComplexity
  end
end
