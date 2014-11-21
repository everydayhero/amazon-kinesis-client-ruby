require 'spec_helper'

describe Kcl::Executor do
  describe '#initialize' do
    context 'When no block provided' do
      it { expect { Kcl::Executor.new }.to raise_error LocalJumpError  }
    end
  end

  describe '.run' do
    context 'Without initialize with #new' do
      it { expect { Kcl::Executor.run }.to raise_error 'Executor not configured' }
    end

    context 'With executor initialized' do
      before {
        expect_any_instance_of(Kcl::Executor).to receive(:run)

        Kcl::Executor.new {}
      }

      it { expect Kcl::Executor.run }
    end
  end
end
