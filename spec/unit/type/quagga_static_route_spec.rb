require 'spec_helper'

describe Puppet::Type.type(:quagga_static_route) do
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
    Puppet::Type.type(:quagga_static_route).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_static_route)
  end

  it 'has prefix, nexthop be its namevar' do
    expect(described_class.key_attributes).to eq([:prefix, :nexthop])
  end

  describe 'when validating attributes' do
    [:prefix, :nexthop, :provider].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:distance, :option].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'supports present as a value' do
        expect { described_class.new(title: '192.168.0.0/16', ensure: :present) }.not_to raise_error
      end

      it 'supports absent as a value' do
        expect { described_class.new(title: '192.168.0.0/16', ensure: :absent) }.not_to raise_error
      end

      it 'does not support other values' do
        expect { described_class.new(title: '192.168.0.0/16', ensure: :foo) }.to raise_error Puppet::Error, %r{Invalid value}
      end
    end
  end

  describe 'nexthop' do
    it 'supports Null0 as a value' do
      expect { described_class.new(title: '192.168.0.0/16', nexthop: 'Null0') }.not_to raise_error
    end

    it 'supports 192.168.1.1 as a value' do
      expect { described_class.new(title: '192.168.0.0/16', nexthop: '192.168.1.1') }.not_to raise_error
    end

    it 'contains Null0' do
      expect(described_class.new(title: '192.168.0.0/16', nexthop: 'Null0')[:nexthop]).to eq('Null0')
    end
  end

  describe 'distance' do
    it 'accepts numeric distances' do
      expect { described_class.new(title: '192.168.0.0/16', distance: 100) }.not_to raise_error
    end

    it 'raises an error if given a non-numeric distance' do
      expect { described_class.new(title: '192.168.0.0/16', distance: '200') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'outputs a matching distance value' do
      expect(described_class.new(title: '192.168.0.0/16', distance: 50)[:distance]).to eq(50)
    end
  end

  describe 'option' do
    it 'supports blackhole as a value' do
      expect { described_class.new(title: '192.168.0.0/16 10.0.0.1', option: :blackhole) }.not_to raise_error
    end

    it 'supports reject as a value' do
      expect { described_class.new(title: '192.168.0.0/16 10.0.0.1', option: :reject) }.not_to raise_error
    end

    it 'does not support foo as a value' do
      expect { described_class.new(title: '192.168.0.0/16 10.0.0.1', option: :foo) }.to raise_error Puppet::Error, %r{Invalid value}
    end
  end
end
