require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_address_family) do
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
    allow(Puppet::Type.type(:quagga_bgp_address_family)).to receive(:defaultprovider).and_return(providerclass)
  end

  it "has :proto, :type be it's namevar" do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:aggregate_address, :maximum_ebgp_paths, :maximum_ibgp_paths, :networks].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'name' do
    it 'supports \'ipv4_unicast\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast') }.not_to raise_error
    end

    it 'supports \'ipv6_unicast\' as a value' do
      expect { described_class.new(name: 'ipv6_unicast') }.not_to raise_error
    end

    it 'supports \'ipv4_multicast\' as a value' do
      expect { described_class.new(name: 'ipv4_multicast') }.not_to raise_error
    end

    it 'does not support \'ipv6_foo\' as a value' do
      expect { described_class.new(name: 'ipv6_foo') }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'does not support \'ipv6\' as a value' do
      expect { described_class.new(name: 'ipv6') }.to raise_error(Puppet::Error, %r{Invalid value})
    end
  end

  describe 'aggregate_address' do
    it 'supports \'192.168.0.0/24\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', aggregate_address: '192.168.0.0/24') }.not_to raise_error
    end

    it 'supports \'192.168.0.0/24 as-set\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', aggregate_address: '192.168.0.0/24 as-set') }.not_to raise_error
    end

    it 'supports \'2a00::/64 summary-only\' as a value' do
      expect { described_class.new(name: 'ipv6_unicast', aggregate_address: '2a00::/64 summary-only') }.not_to raise_error
    end

    it 'does not support \'256.255.255.0/24\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', aggregate_address: '256.255.255.0/24') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support \'2a00::/64\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', aggregate_address: '2a00::/64') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support \'192.168.0.0/24\' as a value' do
      expect { described_class.new(name: 'ipv6_unicast', aggregate_address: '192.168.0.0/24') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support \'2a00::/64 as-set\' as a value' do
      expect { described_class.new(name: 'ipv6_unicast', aggregate_address: '2a00::/64 as-set') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains \'2a00::/64 summary-only\'' do
      expect(described_class.new(name: 'ipv6_unicast', aggregate_address: '2a00::/64 summary-only')[:aggregate_address]).to eq(['2a00::/64 summary-only'])
    end
  end

  [:maximum_ebgp_paths, :maximum_ibgp_paths].each do |property|
    describe property.to_s do
      it 'supports 2 as a value' do
        expect { described_class.new(name: 'ipv4_unicast', property => 2) }.not_to raise_error
      end

      it 'supports \'5\' as a value' do
        expect { described_class.new(name: 'ipv4_unicast', property => '5') }.not_to raise_error
      end

      it 'does not support -1 as a value' do
        expect { described_class.new(name: 'ipv4_unicast', property => -1) }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'does not support \'0\' as a value' do
        expect { described_class.new(name: 'ipv4_unicast', property => '0') }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'does not support 300 as a value' do
        expect { described_class.new(name: 'ipv6_unicast', property => 300) }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'does not support \'-6\' as a value' do
        expect { described_class.new(name: 'ipv6_unicast', property => '-6') }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'does not support 3 as a value' do
        expect { described_class.new(name: 'ipv4_multicast', property => 3) }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'does not support 9 as a value' do
        expect { described_class.new(name: 'ipv6_unicast', property => 9) }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'contains 10' do
        expect(described_class.new(name: 'ipv4_unicast', property => '10')[property]).to eq(10)
      end
    end
  end

  describe 'networks' do
    it 'supports \'192.168.0.0/24\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', networks: '192.168.0.0/24') }.not_to raise_error
    end

    it 'does not support \'256.168.0.0/24\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', networks: '256.168.0.0/24') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support \'224.0.0.0/24\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', networks: '224.0.0.0/24') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support \'10.0.0.0/24\' as a value' do
      expect { described_class.new(name: 'ipv4_multicast', networks: '10.0.0.0/24') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains [\'192.168.0.0/16\']' do
      expect(described_class.new(name: 'ipv4_unicast', networks: '192.168.0.0/16')[:networks]).to eq(['192.168.0.0/16'])
    end

    it 'contains [\'239.0.0.0/8\', \'233.0.0.0/8\']' do
      expect(described_class.new(name: 'ipv4_multicast', networks: ['239.0.0.0/8', '233.0.0.0/8'])[:networks]).to eq(['239.0.0.0/8', '233.0.0.0/8'])
    end

    it 'contains [\'2a00::/64\']' do
      expect(described_class.new(name: 'ipv6_unicast', networks: '2a00::/64')[:networks]).to eq(['2a00::/64'])
    end
  end

  describe 'redistribute' do
    it 'supports \'ospf\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', redistribute: 'ospf') }.not_to raise_error
    end

    it 'supports \'connected route-map QWER\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', redistribute: 'connected route-map QWER') }.not_to raise_error
    end

    it 'does not support \'ospf\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', redistribute: 'bgp') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support \'kernel metric 100 metric-type 3 route-map QWER\' as a value' do
      expect { described_class.new(name: 'ipv4_unicast', redistribute: 'kernel metric 100 metric-type 3 route-map QWER') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains \'connected metric 100 metric-type 2 route-map QWER\'' do
      expect(described_class.new(name: 'ipv4_unicast', redistribute: 'connected metric 100 route-map QWER')[:redistribute]).to eq(['connected metric 100 route-map QWER'])
    end
  end
end
