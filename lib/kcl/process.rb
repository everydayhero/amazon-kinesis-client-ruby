module Kcl
  class Process
    def initialize record_processor,
                   input: $stdin,
                   output: $stdout,
                   error: $stderr
      @record_processor = record_processor
      @io_handler = IOHandler.new input, output, error
      @checkpointer = Checkpointer.new @io_handler
    end

    def run
      loop do
        action = io_handler.read_action
        perform action
        report_done action

        break if action.nil?
      end
    end

    private

    attr_reader :record_processor, :io_handler, :checkpointer

    def perform action
      action_handler.handle action
    end

    def action_handler
      @action_handler ||=
        ActionHandler.new record_processor, checkpointer, io_handler
    end

    def report_done action
      io_handler.write_action action: 'status', responseFor: action['action']
    end
  end
end
