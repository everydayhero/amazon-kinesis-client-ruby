module Kcl
  class ExecutorCommandBuilder
    def initialize properties_file_path, system_properties: {},
                                         extra_class_path: []
      @properties_file_path = properties_file_path
      @system_properties = system_properties
      @extra_class_path = extra_class_path
    end

    def build
      [
        java, system_property_options, '-cp', class_path,
        client_class, properties_file
      ].flatten
    end

    private

    attr_reader :properties_file_path, :extra_class_path, :system_properties

    def java
      command = ENV.fetch('PATH_TO_JAVA', `which java`).strip
      fail 'Missing JAVA PATH' if command.nil? || command.empty?

      command
    end

    def client_class
      'com.amazonaws.services.kinesis.multilang.MultiLangDaemon'
    end

    def class_path
      (
        Dir["#{jar_dir}/*.jar"].concat(extra_class_path) << properties_file_dir
      ).join ':'
    end

    def properties_file
      @properties_file ||= File.basename properties_file_path
    end

    def properties_file_dir
      @properties_file_dir ||= File.dirname properties_file_path
    end

    def system_property_options
      @system_property_options ||= system_properties.map do |key, value|
        "-D#{key}=#{value}"
      end
    end

    def jar_dir
      @jar_dir ||= File.expand_path '../../jars', __FILE__
    end
  end
end
