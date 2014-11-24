module Kcl
  class ExecutorCommandBuilder
    def initialize properties_file_path
      @properties_file_path = properties_file_path
    end

    def build
      [java, log4j_config, '-cp', class_path, client_class, properties_file]
    end

    private

    attr_reader :properties_file_path

    def java
      command = ENV.fetch('PATH_TO_JAVA', `which java`).strip
      fail 'Missing JAVA PATH' if command.nil? || command.empty?

      command
    end

    def client_class
      'com.amazonaws.services.kinesis.multilang.MultiLangDaemon'
    end

    def class_path
      (Dir["#{jar_dir}/*.jar"] << properties_file_dir).join ':'
    end

    def properties_file
      @properties_file ||= File.basename properties_file_path
    end

    def properties_file_dir
      @properties_file_dir ||= File.dirname properties_file_path
    end

    def log4j_config
      config_file = "#{jar_dir}/log4j.properties"

      "-Dlog4j.configuration=file:#{config_file}"
    end

    def jar_dir
      @jar_dir ||= File.expand_path '../../jars', __FILE__
    end
  end
end
