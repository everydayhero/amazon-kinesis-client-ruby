module Kcl
  class Checkpointer
    def initialize io_handler
      @io_handler = io_handler
    end

    def checkpoint sequence_number = nil
      io_handler.write_action action: 'checkpoint', checkpoint: sequence_number

      action = get_action
      if action['action'] == 'checkpoint'
        raise CheckpointError.new action['error'] unless action['error'].nil?
      else
        raise CheckpointError.new 'InvalidStateException'
      end
    end

    private

    attr_reader :io_handler

    def get_action
      begin
        action = fetch_action
      end while action.nil?
      action
    end

    def fetch_action
      io_handler.read_action
    rescue IOHandler::ReadError => read_error
      io_handler.write_error \
        "Could not understand line read from input: #{read_error.line}"
    end
  end
end
