module Kcl
  class ActionHandler
    def initialize record_processor, checkpointer, io_handler
      @record_processor = record_processor
      @checkpointer = checkpointer
      @io_handler = io_handler
    end

    # rubocop:disable Style/MethodLength
    def handle action
      case action.fetch('action')
      when 'initialize'
        record_processor.init action.fetch('shardId')
      when 'processRecords'
        record_processor.process_records action.fetch('records'), checkpointer
      when 'shutdown'
        record_processor.shutdown checkpointer, action.fetch('reason')
      else
        fail MalformedActionError,
             "Received an action which couldn't be understood. Action was #{action}"
      end
    rescue KeyError => key_error
      raise MalformedActionError,
            "Action #{action} was expected to have key: #{key_error.message}"
    rescue => error
      io_handler.write_error error.backtrace.join "\n"
    end
    # rubocop:enable Style/MethodLength

    private

    attr_reader :record_processor, :io_handler, :checkpointer
  end
end
