require 'spec_helper'

describe Kcl::ExecutorCommandBuilder do
  let(:properties_file_path) { File.expand_path __FILE__ }
  let(:builder) { Kcl::ExecutorCommandBuilder.new properties_file_path }

  describe '#build' do
    let(:command) { builder.build }

    describe 'comamnd<java>' do
      let(:java) { command[0] }

      context 'With PATH_TO_JAVA environment variable' do
        before { ENV['PATH_TO_JAVA'] = 'my_java' }

        it { expect(java).to eq 'my_java' }
      end

      context 'Without PATH_TO_JAVA set' do
        before { ENV['PATH_TO_JAVA'] = nil }

        it { expect(java).to eq `which java`.strip }
      end

      context 'Without java executable available' do
        before {
          ENV['PATH_TO_JAVA'] = nil
          allow(builder).to receive(:'`').with('which java').and_return ''
        }

        it { expect { java }.to raise_error 'Missing JAVA PATH' }
      end
    end

    describe 'command<-cp>' do
      it { expect(command[1]).to eq '-cp' }
    end

    describe 'command<classpath>' do
      let(:classpath) { command[2] }

      it { expect(classpath).to match(/\A(.+\.jar\:)+.+\z/) }

      it { expect(classpath).to include File.dirname(properties_file_path) }
    end

    describe 'command<client_class>' do
      let(:client_class) { command[3] }
      let(:expected_client_class) {
        'com.amazonaws.services.kinesis.multilang.MultiLangDaemon'
      }

      it { expect(client_class).to eq expected_client_class }
    end

    describe 'command<properties_file>' do
      let(:properties_file) { command[4] }

      it { expect(properties_file).to eq File.basename(properties_file_path) }
    end

    context 'With system properties' do
      let(:builder) {
        system_properties = {
          'log4j.configuration' => 'log4j.properties',
          option2: 'test'
        }

        Kcl::ExecutorCommandBuilder.new properties_file_path,
                                        system_properties: system_properties
      }

      it { expect(command).to include '-Dlog4j.configuration=log4j.properties' }

      it { expect(command).to include '-Doption2=test' }
    end

    context 'With extra_class_path' do
      let(:classpath) { command[2] }

      let(:builder) {
        Kcl::ExecutorCommandBuilder.new properties_file_path,
                                        extra_class_path: ['test.jar']
      }

      it { expect(classpath).to include 'test.jar' }
    end
  end
end
