require 'spec_helper'
require 'stringio'

describe Kcl::IOHandler do
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }
  let(:error) { StringIO.new }

  subject { Kcl::IOHandler.new input, output, error }

  describe '#write_action' do
    let(:action) { { action: 'test', value: 123 } }

    before { subject.write_action action }

    it { expect(output.string).to eq "\n#{action.to_json}\n" }

    it { expect(input.string).to eq '' }

    it { expect(error.string).to eq '' }
  end

  describe '#write_error' do
    let(:message) { 'Some error' }

    before { subject.write_error message }

    it { expect(error.string).to eq "#{message}\n" }

    it { expect(input.string).to eq '' }

    it { expect(output.string).to eq '' }
  end

  describe '#read_action' do
    context 'With empty line input' do
      it { expect(subject.read_action).to be_nil }
    end

    context 'With valid action input' do
      let(:action) { { 'action' => 'test', 'value' => 1 } }

      before { input.string = action.to_json }

      it { expect(subject.read_action).to eq action }
    end

    context 'With invalid action input' do
      before { input.string = 'dummy' }

      it {
        expect { subject.read_action }.to raise_error Kcl::IOHandler::ReadError
      }
    end
  end
end
