require 'spec_helper'

describe Puppet::Type.type(:quagga_as_path) do
  let :providerclass  do
    described_class.provide(:fake_quagga_provider) do
      attr_accessor :property_hash
      def create; end
      def destroy; end
      def exists?
        get(:ensure) == :present
      end
      mk_resource_methods
    end
  end

  before :each do
    Puppet::Type.type(:quagga_as_path).stubs(:defaultprovider).returns providerclass
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

    [ :rules ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'as100', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'as100', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'as100', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'name' do
    it 'should support as100 as a value' do
      expect { described_class.new(:name => 'as100') }.to_not raise_error
    end

    it 'should support as100 as a value' do
      expect { described_class.new(:name => 'as100') }.to_not raise_error
    end

    it 'should not support as100 as a value' do
      expect { described_class.new(:name => 'as100:1') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  describe 'rules' do
    it 'should support \'premit _100$\' as a value' do
      expect { described_class.new(:name => 'as100', :rules => 'permit _100$') }.to_not raise_error
    end

    it 'should support [\'permit _100$\', \'permit _100_\'] as a value' do
      expect { described_class.new(:name => 'as100', :rules => ['permit _100$', 'permit _100_']) }.to_not raise_error
    end

    it 'should not support [\'permit _10X$\', \'permit _100_\'] as a value' do
      expect { described_class.new(:name => 'as100', :rules => ['permit _10X$', 'permit _100_']) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support [\'reject _100$\', \'permit _100_\'] as a value' do
      expect { described_class.new(:name => 'as100', :rules => ['reject _100$', 'permit _100_']) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain [\'permit _100$\']' do
      expect(described_class.new(:name => 'as100', :rules => 'permit _100$')[:rules]).to eq(['permit _100$'])
    end

    it 'should contain [\'permit _100$\', \'permit _100_\']' do
      expect(described_class.new(:name => 'as100', :rules => ['permit _100$', 'permit _100_'])[:rules]).to eq(['permit _100$', 'permit _100_'])
    end
  end
end