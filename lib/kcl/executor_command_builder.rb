module Kcl
  class ExecutorCommandBuilder
    def build
      "#{java} -cp #{class_path} #{client_class} #{properties_file}"
    end

    private

    def java
      command = ENV.fetch('PATH_TO_JAVA', `which java`).strip
      fail 'Missing JAVA PATH' if command.nil? || command.empty?

      command
    end

    def client_class
      'com.amazonaws.services.kinesis.multilang.MultiLangDaemon'
    end

    def class_path
      jar_dir = File.expand_path '../../jars', __FILE__

      Dir["#{jar_dir}/*.jar"].join ':'
    end

    def properties_file
      File.expand_path '../../default.properties', __FILE__
    end
  end
end
