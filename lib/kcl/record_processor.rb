require 'aws/kclrb'
require 'forwardable'

module Kcl
  module RecordProcessor
    def init _shared_id; end

    def process_records _records, _checkpointer; end

    def shutdown _checkpointer, _reason; end

    def run
      processor = RecordProcessorAdapter.new self

      Aws::KCLrb::KCLProcess.new(processor).run
    end

    class RecordProcessorAdapter < Aws::KCLrb::RecordProcessorBase
      extend Forwardable

      def_delegator :@record_processor, :process_records, :shutdown

      def initialize record_processor
        @record_processor = record_processor
      end

      def init_processor shard_id
        @record_processor.init shard_id
      end
    end
  end
end
