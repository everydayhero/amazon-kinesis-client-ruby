require 'ostruct'
require 'active_support/core_ext/string'

module Kcl
  class Configuration < OpenStruct
    def initialize config = {}
      super default_config.merge config
    end

    def to_properties
      check_config

      to_h.map do |key, value|
        "#{make_prop_key key}=#{value}"
      end.join "\n"
    end

    private

    def check_config
      default_config.keys.each do |required_key|
        fail "#{required_key} is required" unless to_h[required_key].present?
      end
    end

    def make_prop_key key
      default_key_map.fetch key, key.to_s.camelize(:lower)
    end

    def application_name
      ENV['APP_NAME']
    end

    def executable_name
      caller.each do |trace|
        matched = trace.match(/\A(?<file>.+)\:\d+\:in.*<main>.*\Z/)

        return matched[:file] if matched
      end
    end

    def processing_language
      "ruby/#{RUBY_VERSION}"
    end

    def default_config
      @default_config ||= {
        executable_name: executable_name,
        application_name: application_name,
        processing_language: processing_language,
        aws_credentials_provider: 'DefaultAWSCredentialsProviderChain',
        initial_position_in_stream: 'TRIM_HORIZON'
      }
    end

    def default_key_map
      {
        aws_credentials_provider: 'AWSCredentialsProvider'
      }
    end
  end
end
