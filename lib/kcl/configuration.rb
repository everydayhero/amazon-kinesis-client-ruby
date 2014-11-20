require 'ostruct'
require 'active_support/core_ext/string'

module Kcl
  class Configuration < OpenStruct
    def initialize config = {}
      super apply_default config
    end

    def to_properties
      to_h.map do |key, value|
        "#{make_prop_key key}=#{value}"
      end.join "\n"
    end

    private

    def make_prop_key key
      default_key_map.fetch key, key.to_s.camelize(:lower)
    end

    def apply_default config
      default_config = {
        executable_name: executable_name,
        application_name: application_name,
        aws_credentials_provider: 'DefaultAWSCredentialsProviderChain',
        processing_language: 'ruby/2.1.2',
        initial_position_in_stream: 'TRIM_HORIZON'
      }

      default_config.merge config
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

    def default_key_map
      {
        aws_credentials_provider: 'AWSCredentialsProvider'
      }
    end
  end
end
