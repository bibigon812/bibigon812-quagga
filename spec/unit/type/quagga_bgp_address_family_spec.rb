require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_address_family) do
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

  it 'should have :name be it\'s namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider,].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:aggregate_address, :maximum_ebgp_paths, :maximum_ibgp_paths, :networks,].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'name' do
    it 'should support \'65000 ipv4 unicast\' as a value' do
      expect { described_class.new(:name => '65000 ipv4 unicast') }.to_not raise_error
    end

    it 'should support \'65000 ipv6\' as a value' do
      expect { described_class.new(:name => '65000 ipv6') }.to_not raise_error
    end

    it 'should support \'65000 ipv4 multicast\' as a value' do
      expect { described_class.new(:name => '65000 ipv4 multicast') }.to_not raise_error
    end

    it 'should not support \'65000 ipv6 unicast\' as a value' do
      expect { described_class.new(:name => '65000 ipv6 unicast') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  describe 'aggregate_address' do
    it 'should support \'192.168.0.0/24\' as a value' do
      expect { described_class.new(:name => '65000 ipv4 unicast', :aggregate_address => '192.168.0.0/24') }.to_not raise_error
    end

    it 'should support \'192.168.0.0/24 as-set\' as a value' do
      expect { described_class.new(:name => '65000 ipv4 unicast', :aggregate_address => '192.168.0.0/24 as-set') }.to_not raise_error
    end

    it 'should support \'2a00::/64 summary-only\' as a value' do
      expect { described_class.new(:name => '65000 ipv6', :aggregate_address => '2a00::/64 summary-only') }.to_not raise_error
    end

    it 'should not support \'256.255.255.0/24\' as a value' do
      expect { described_class.new(:name => '65000 ipv4 unicast', :aggregate_address => '256.255.255.0/24') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support \'2a00::/64\' as a value' do
      expect { described_class.new(:name => '65000 ipv4 unicast', :aggregate_address => '2a00::/64') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support \'192.168.0.0/24\' as a value' do
      expect { described_class.new(:name => '65000 ipv6', :aggregate_address => '192.168.0.0/24') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support \'2a00::/64 as-set\' as a value' do
      expect { described_class.new(:name => '65000 ipv6 unicast', :aggregate_address => '2a00::/64 as-set') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain \'2a00::/64 summary-only\'' do
      expect(described_class.new(:name => '65000 ipv6', :aggregate_address => '2a00::/64 summary-only')[:aggregate_address]).to eq('2a00::/64 summary-only')
    end
  end

  [:maximum_ebgp_paths, :maximum_ibgp_paths].each do |property|
    describe "#{property}" do
      it 'should support 2 as a value' do
        expect { described_class.new(:name => '65000 ipv4 unicast', property => 2) }.to_not raise_error
      end

      it 'should support \'5\' as a value' do
        expect { described_class.new(:name => '65000 ipv4 unicast', property => '5') }.to_not raise_error
      end

      it 'should not support -1 as a value' do
        expect { described_class.new(:name => '65000 ipv4 unicast', property => -1) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support \'0\' as a value' do
        expect { described_class.new(:name => '65000 ipv4 unicast', property => '0') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 300 as a value' do
        expect { described_class.new(:name => '65000 ipv6', property => 300) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support \'-6\' as a value' do
        expect { described_class.new(:name => '65000 ipv6 unicast', property => '-6') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 3 as a value' do
        expect { described_class.new(:name => '65000 ipv4 multicast', property => 3) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 9 as a value' do
        expect { described_class.new(:name => '65000 ipv6', property => 9) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should contain 10' do
        expect(described_class.new(:name => '65000 ipv4 unicast', property => '10')[property]).to eq(10)
      end
    end
  end

  describe 'networks' do
    it 'should support \'192.168.0.0/24\' as a value' do
      expect { described_class.new(:name => '65000 ipv4 unicast', :networks => '192.168.0.0/24') }.to_not raise_error
    end

    it 'should not support \'256.168.0.0/24\' as a value' do
      expect { described_class.new(:name => '65000 ipv4 unicast', :networks => '256.168.0.0/24') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support \'224.0.0.0/24\' as a value' do
      expect { described_class.new(:name => '65000 ipv4 unicast', :networks => '224.0.0.0/24') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support \'10.0.0.0/24\' as a value' do
      expect { described_class.new(:name => '65000 ipv4 multicast', :networks => '10.0.0.0/24') }.to raise_error Puppet::Error, /Invalid value/
    end
  end
end
