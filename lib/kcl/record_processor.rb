module Kcl
  module RecordProcessor
    def init
      raise NotImplementedError
    end

    def process_records
      raise NotImplementedError
    end

    def shutdown
      raise NotImplementedError
    end

    def run
      Process.new(self).run
    end
  end
end
