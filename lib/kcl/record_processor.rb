module Kcl
  module RecordProcessor
    def init _shared_id; end

    def process_records _records, _checkpointer; end

    def shutdown _checkpointer, _reason; end

    def run
      Process.new(self).run
    end
  end
end
