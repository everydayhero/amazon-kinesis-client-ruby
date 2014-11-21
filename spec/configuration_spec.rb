require 'spec_helper'

describe Kcl::Configuration do
  describe '#to_properties' do
    let(:config) { Kcl::Configuration.new config_options }

    let(:required_options) {
      {
        application_name: 'MyApp',
        stream_name: 'MyStream'
      }
    }

    let(:config_options) { required_options }

    let(:default_properties) {
      %w(
        AWSCredentialsProvider=DefaultAWSCredentialsProviderChain
        initialPositionInStream=TRIM_HORIZON
      ).join "\n"
    }

    subject { config.to_properties }

    it { is_expected.to match(%r{executableName=.+/exe/rspec}) }

    it { is_expected.to include "processingLanguage=ruby/#{RUBY_VERSION}" }

    it { is_expected.to include default_properties }

    context 'When ruby style config key is set' do
      let(:config_options) {
        {
          dummy_key: 1,
          dummy_key_two: 'two'
        }.merge required_options
      }

      it { is_expected.to include "dummyKey=1\ndummyKeyTwo=two" }
    end

    context 'When aws_credentials_provider is set' do
      let(:config_options) {
        {
          aws_credentials_provider: 'Test'
        }.merge required_options
      }

      it { is_expected.to include 'AWSCredentialsProvider=Test' }
    end

    context 'When APP_NAME environment vairlable is set' do
      before { ENV['APP_NAME'] = 'Test App' }

      let(:config_options) { { stream_name: 'MyStream' } }

      it { is_expected.to include 'applicationName=Test App' }
    end

    %w(
      executable_name application_name processing_language
      aws_credentials_provider initial_position_in_stream stream_name
    ).each do |key_prop|
      context "When missing required property #{key_prop}" do
        let(:config_options) { { key_prop => nil } }

        it { expect { subject }.to raise_error "#{key_prop} is required" }
      end
    end
  end
end
