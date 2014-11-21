module Kcl
  class Checkpointer
    def initialize io_handler
      @io_handler = io_handler
    end

    def checkpoint sequence_number = nil
      io_handler.write_action action: 'checkpoint', checkpoint: sequence_number

      action = fetch_action
      if action['action'] == 'checkpoint'
        fail CheckpointError, action['error'] unless action['error'].nil?
      else
        fail CheckpointError, 'InvalidStateException'
      end
    end

    private

    attr_reader :io_handler

    def fetch_action
      loop do
        action = read_action

        return action unless action.nil?
      end
    end

    def read_action
      io_handler.read_action
    rescue IOHandler::ReadError => read_error
      io_handler.write_error \
        "Could not understand line read from input: #{read_error.line}"
    end
  end
end
