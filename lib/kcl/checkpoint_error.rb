module Kcl
  class CheckpointError < StandardError
    def initialize error_name
      super error_name
      @error_name = error_name
    end

    def to_s
      error_name.to_s
    end

    private

    attr_reader :error_name
  end
end
