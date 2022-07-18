require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_community_list) do
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
    Puppet::Type.type(:quagga_bgp_community_list).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_bgp_community_list)
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
        expect { described_class.new(name: '100', ensure: :present) }.not_to raise_error
      end

      it 'supports absent as a value' do
        expect { described_class.new(name: '100', ensure: :absent) }.not_to raise_error
      end

      it 'does not support other values' do
        expect { described_class.new(name: '100', ensure: :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end
  end

  describe 'name' do
    it 'supports quoted string "100" as a value' do
      expect { described_class.new(name: '100') }.not_to raise_error
    end

    it 'does not support as100 as a value' do
      expect { described_class.new(name: 'as100') }.to raise_error(Puppet::Error, %r{Community list number: 1-500})
    end
  end

  describe 'rules' do
    it 'supports \'premit 65000:1\' as a value' do
      expect { described_class.new(name: '100', rules: 'permit 65000:1') }.not_to raise_error
    end

    it 'supports [\'permit 65000:1\', \'permit 65000:2\'] as a value' do
      expect { described_class.new(name: '100', rules: ['permit 65000:1', 'permit 65000:2']) }.not_to raise_error
    end

    it 'does not support [\'permit AS65000:1\', \'permit => 65000:2\'] as a value' do
      expect { described_class.new(name: '100', rules: ['permit AS65000:1', 'permit 65000:2']) }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support [\'reject 65000:1\', \'permit 65000:2\'] as a value' do
      expect { described_class.new(name: '100', rules: ['reject 65000:1', 'permit 65000:2']) }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains [\'permit 65000:1\']' do
      expect(described_class.new(name: '100', rules: 'permit 65000:1')[:rules]).to eq(['permit 65000:1'])
    end

    it 'contains [\'permit 65000:1\', \'permit 65000:2\']' do
      expect(described_class.new(name: '100', rules: ['permit 65000:1', 'permit 65000:2'])[:rules]).to eq(['permit 65000:1', 'permit 65000:2'])
    end
  end
end
