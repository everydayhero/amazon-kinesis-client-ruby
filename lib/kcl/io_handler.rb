require 'json'

module Kcl
  class IOHandler
    def initialize input, output, error
      @input = input
      @output = ouput
      @error = error
    end

    def write_action response
      write_line response.to_json
    end

    def read_action
      line = input.gets
      JSON.parse line unless line.nil? || line.empty?
    rescue => error
      raise ReadError.new(error, line)
    end

    def write_error error_message
      error << "#{error_message}\n"
    ensure
      error.flush
    end

    private

    attr_reader :input, :output, :error

    def write_line line
      output << "\n#{line}\n"
    ensure
      output.flush
    end

    class ReadError < StandardError
      attr_reader :base_error, :line

      def initialize base_error, line
        super base_error.message
        @base_error = base_error
        @line = line
      end
    end
  end
end
