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

    [:action, :regex].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'from_as100:1', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'from_as100:1', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'from_as100:1', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'action' do
    it 'should support permit as a value' do
      expect { described_class.new(:name => 'from_as100:1', :action => :permit) }.to_not raise_error
    end

    it 'should support deny as a value' do
      expect { described_class.new(:name => 'from_as100:1', :action => :deny) }.to_not raise_error
    end

    it 'should not support accept as a value' do
      expect { described_class.new(:name => 'from_as100:1', :action => :accept) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain permit' do
      expect(described_class.new(:name => 'from_as100:1', :action => :permit)[:action]).to eq(:permit)
    end

    it 'should contain permit' do
      expect(described_class.new(:name => 'from_as100:1', :action => 'permit')[:action]).to eq(:permit)
    end
  end

  describe 'regex' do
    it 'should support _100$ as a value' do
      expect { described_class.new(:name => 'from_as100:1', :regex => '_100$') }.to_not raise_error
    end

    it 'should support _100_200.$ as a value' do
      expect { described_class.new(:name => 'from_as100:1', :regex => '_100_200.$') }.to_not raise_error
    end

    it 'should support ^100_100$ as a value' do
      expect { described_class.new(:name => 'from_as100:1', :regex => '^100_\\100$') }.to_not raise_error
    end

    it 'should support ^100*_100+$ as a value' do
      expect { described_class.new(:name => 'from_as100:1', :regex => '^100*_100_$') }.to_not raise_error
    end

    it 'should not support ^100^_100$ as a value' do
      expect { described_class.new(:name => 'from_as100:1', :regex => '^100^_100$') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain _100_100$' do
      expect(described_class.new(:name => 'from_as100:1', :regex => '_100_100$')[:regex]).to eq('_100_100$')
    end

    it 'should contain ^100_200.$' do
      expect(described_class.new(:name => 'from_as100:1', :regex => '^100_200.$')[:regex]).to eq('^100_200.$')
    end
  end
end