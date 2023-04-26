require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_as_path) do
  let :providerclass do
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
    allow(Puppet::Type.type(:quagga_bgp_as_path)).to receive(:defaultprovider).and_return(providerclass)
  end

  it 'has :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [ :rules ].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'supports present as a value' do
        expect { described_class.new(name: 'as100', ensure: :present) }.not_to raise_error
      end

      it 'supports absent as a value' do
        expect { described_class.new(name: 'as100', ensure: :absent) }.not_to raise_error
      end

      it 'does not support other values' do
        expect { described_class.new(name: 'as100', ensure: :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end
  end

  describe 'name' do
    it 'supports ASN as100 as a value' do
      expect { described_class.new(name: 'as100') }.not_to raise_error
    end

    it 'does not support RD as100:1 as a value' do
      expect { described_class.new(name: 'as100:1') }.to raise_error(Puppet::Error, %r{Invalid value})
    end
  end

  describe 'rules' do
    it 'supports \'premit _100$\' as a value' do
      expect { described_class.new(name: 'as100', rules: 'permit _100$') }.not_to raise_error
    end

    it 'supports \'permit ^([{},0-9]+_){50}\' as a value' do
      expect { described_class.new(name: 'as100', rules: 'permit ^([{},0-9]+_){50}') }.not_to raise_error
    end

    it 'supports [\'permit _100$\', \'permit _100_\'] as a value' do
      expect { described_class.new(name: 'as100', rules: ['permit _100$', 'permit _100_']) }.not_to raise_error
    end

    it 'does not support [\'permit _10X$\', \'permit _100_\'] as a value' do
      expect { described_class.new(name: 'as100', rules: ['permit _10X$', 'permit _100_']) }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'does not support [\'reject _100$\', \'permit _100_\'] as a value' do
      expect { described_class.new(name: 'as100', rules: ['reject _100$', 'permit _100_']) }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'contains [\'permit _100$\']' do
      expect(described_class.new(name: 'as100', rules: 'permit _100$')[:rules]).to eq(['permit _100$'])
    end

    it 'contains [\'permit _100$\', \'permit _100_\']' do
      expect(described_class.new(name: 'as100', rules: ['permit _100$', 'permit _100_'])[:rules]).to eq(['permit _100$', 'permit _100_'])
    end
  end
end
