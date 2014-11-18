require 'base64'
require 'logger'

module Kcl
  class AdvancedRecordProcessor
    include RecordProcessor

    LOG = Logger.new STDOUT
    ERR_LOG = Logger.new STDERR

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

    def init _shared_id
      self.largest_seq = nil
      self.last_checkpoint_time = Time.now
    end

    def process_records records, checkpointer
      records.each do |record|
        handle_record record
      end

      if Time.now - last_checkpoint_time > checkpoint_freq_seconds
        checkpoint checkpointer
        self.last_checkpoint_time = Time.now
      end
    rescue => error
      ERR_LOG.error "Encountered an exception while processing records. Exception was #{error}\n"
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

    # rubocop:disable Style/MethodLength,Style/CyclomaticComplexity
    def try_checkpoint checkpointer, sequence_number, try_count
      seq = sequence_number.to_s if sequence_number
      checkpointer.checkpoint seq

      true
    rescue CheckpointError => checkpoint_error
      case checkpoint_error.to_s
      when 'ShutdownException'
        LOG.info 'Encountered shutdown execption, skipping checkpoint'
        true
      when 'ThrottlingException'
        if checkpoint_retries - 1 == try_count
          ERR_LOG.error "Failed to checkpoint after #{try_count} attempts, giving up.\n"
          true
        else
          LOG.info "Was throttled while checkpointing, will attempt again in #{sleep_seconds} seconds"
          false
        end
      when 'InvalidStateException'
        ERR_LOG.error "MultiLangDaemon reported an invalid state while checkpointing.\n"
        false
      else
        ERR_LOG.error "Encountered an error while checkpointing, error was #{checkpoint_error}.\n"
        false
      end
    end
    # rubocop:enable Style/MethodLength,Style/CyclomaticComplexity
  end
end
