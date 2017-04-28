require 'spec_helper'

describe Puppet::Type.type(:as_path) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:as_path) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:as_path)
  end

  it 'should have :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'from_as100:permit:_100$', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'from_as100:permit:_100$', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'from_as100:permit:_100$', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'name' do
    it 'should support from_as100:permit:^100$ as a value' do
      expect { described_class.new(:name => 'from_as100:permit:^100$') }.to_not raise_error
    end

    it 'should support from_as100:permit:^100_100$ as a value' do
      expect { described_class.new(:name => 'from_as100:deny:^100_100$') }.to_not raise_error
    end

    it 'should not support accept as a value' do
      expect { described_class.new(:name => 'from_as100:1') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end
end