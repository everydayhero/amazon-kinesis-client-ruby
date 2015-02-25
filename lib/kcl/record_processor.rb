require 'aws/kclrb'

module Kcl
  module RecordProcessor
    def init _shard_id; end

    def process_records _records, _checkpointer; end

    def shutdown _checkpointer, _reason; end

    def run
      processor = RecordProcessorAdapter.new self

      Aws::KCLrb::KCLProcess.new(processor).run
    end

    class RecordProcessorAdapter < Aws::KCLrb::RecordProcessorBase
      def initialize record_processor
        @record_processor = record_processor
      end

      def init_processor shard_id
        record_processor.init shard_id
      end

      def shutdown checkpointer, reason
        record_processor.shutdown checkpointer, reason
      end

      def process_records records, checkpointer
        record_processor.process_records records, checkpointer
      end

      private

      attr_reader :record_processor
    end
  end
end
