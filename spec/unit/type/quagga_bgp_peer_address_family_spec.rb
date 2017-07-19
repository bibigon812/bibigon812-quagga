require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_peer_address_family) do
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

  let(:route_map_10) { Puppet::Type.type(:quagga_route_map).new(:name => 'ROUTE_MAP 10') }
  let(:route_map_20) { Puppet::Type.type(:quagga_route_map).new(:name => 'ROUTE_MAP 20') }
  let(:catalog) { Puppet::Resource::Catalog.new }

  before :each do
    Puppet::Type.type(:quagga_bgp_peer_address_family).stubs(:defaultprovider).returns providerclass
  end

  it "should have :proto, :type be it's namevar" do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider,].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [
      :peer_group, :activate, :allow_as_in, :default_originate, :next_hop_self,
      :prefix_list_in, :prefix_list_out,
      :route_map_export, :route_map_import, :route_map_in, :route_map_out,
      :route_reflector_client, :route_server_client,
    ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'name' do
    it 'should support \'INTERNAL ipv6_unicast\' as a value' do
      expect { described_class.new(:name => 'INTERNAL ipv6_unicast') }.to_not raise_error
    end

    it 'should support \'INTERNAL ipv4_multicast\' as a value' do
      expect { described_class.new(:name => 'INTERNAL ipv4_multicast') }.to_not raise_error
    end

    it 'should not support \'INTERNAL ipv6_foo\' as a value' do
      expect { described_class.new(:name => 'INTERNAL ipv6_foo') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support \'INTERNAL ipv6\' as a value' do
      expect { described_class.new(:name => 'INTERNAL ipv6') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  [
    :activate, :default_originate, :next_hop_self,
    :route_reflector_client, :route_server_client,
  ].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'should support \'true\' as a value' do
        expect { described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => 'true') }.to_not raise_error
      end

      it 'should support :true as a value' do
        expect { described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => :true) }.to_not raise_error
      end

      it 'should support true as a value' do
        expect { described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => true) }.to_not raise_error
      end

      it 'should support \'false\' as a value' do
        expect { described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => 'false') }.to_not raise_error
      end

      it 'should support :false as a value' do
        expect { described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => :false) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => false) }.to_not raise_error
      end

      it 'should not support :enabled as a value' do
        expect { described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => :enabled) }.to raise_error Puppet::Error
      end

      it 'should not support \'disabled\' as a value' do
        expect { described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => 'disabled') }.to raise_error Puppet::Error
      end

      it 'should contain \'true\' => true' do
        expect(described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => 'true')[property]).to eq(:true)
      end

      it 'should contain true => true' do
        expect(described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => true)[property]).to eq(:true)
      end

      it 'should contain :true => true' do
        expect(described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => :true)[property]).to eq(:true)
      end

      it 'should contain \'false\' => false' do
        expect(described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => 'false')[property]).to eq(:false)
      end

      it 'should contain false => false' do
        expect(described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => false)[property]).to eq(:false)
      end

      it 'should contain false => false' do
        expect(described_class.new(:name => '10.0.0.1 ipv4_multicast', :peer_group => :false, property => :false)[property]).to eq(:false)
      end
    end
  end

  [
    :prefix_list_in, :prefix_list_out, :route_map_export, :route_map_import,
    :route_map_in, :route_map_out
  ].each do |property|
    describe "string values of the property `#{property}`" do
      it "should support \"#{property.to_s.upcase}\" as a value" do
        expect { described_class.new(:name => '2001:db8::1 ipv6_unicast', :peer_group => :false, property => property.to_s.upcase) }.to_not raise_error
      end

      it "should not support \"9#{property.to_s.upcase}\" as a value" do
        expect { described_class.new(:name => '2001:db8::1 ipv6_unicast', :peer_group => :false, property => "9#{property.to_s.upcase}") }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it "should contain \"#{property.to_s.upcase}\"" do
        expect(described_class.new(:name => '2001:db8::1 ipv6_unicast', :peer_group => :false, property => property.to_s.upcase)[property]).to eq(property.to_s.upcase)
      end

      it "should contain \"#{property.to_s.upcase}\"" do
        expect(described_class.new(:name => 'INTERNAL ipv4_unicast', property => property.to_s.upcase)[property]).to eq(property.to_s.upcase)
      end
    end
  end

  describe 'peer_group' do
    it 'should support \'true\' as a value' do
      expect { described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => 'true') }.to_not raise_error
    end

    it 'should support :true as a value' do
      expect { described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => :true) }.to_not raise_error
    end

    it 'should support true as a value' do
      expect { described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => true) }.to_not raise_error
    end

    it 'should support \'false\' as a value' do
      expect { described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => 'false') }.to_not raise_error
    end

    it 'should support :false as a value' do
      expect { described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => :false) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => false) }.to_not raise_error
    end

    it 'should support peer_group as a value' do
      expect { described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => 'peer_group') }.to_not raise_error
    end

    it 'should support peer_group_1 as a value' do
      expect { described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => :peer_group_1) }.to_not raise_error
    end

    it 'should not support 9-allow as a value' do
      expect { described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => '9-allow') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain true' do
      expect(described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => 'true')[:peer_group]).to eq(:true)
    end

    it 'should contain true' do
      expect(described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => true)[:peer_group]).to eq(:true)
    end

    it 'should contain fasle' do
      expect(described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => 'false')[:peer_group]).to eq(:false)
    end

    it 'should contain :false' do
      expect(described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => false)[:peer_group]).to eq(:false)
    end

    it 'should contain peer_group' do
      expect(described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => 'peer_group')[:peer_group]).to eq('peer_group')
    end

    it 'should contain peer_group_1' do
      expect(described_class.new(:name => '2001:db8:: ipv6_unicast', :peer_group => 'peer_group_1')[:peer_group]).to eq('peer_group_1')
    end
  end

  describe 'when autosubscribe' do
    it 'should subscribe on route_map ROUTE_MAP' do
      peer_address_family = described_class.new(:name => 'INTERNAL ipv4_unicast', :route_map_in => 'ROUTE_MAP')
      catalog.add_resource route_map_10
      catalog.add_resource route_map_20
      catalog.add_resource peer_address_family
      reqs = peer_address_family.autosubscribe

      expect(reqs.size).to eq(2)
      expect(reqs[0].source).to eq(route_map_10)
      expect(reqs[0].target).to eq(peer_address_family)
      expect(reqs[1].source).to eq(route_map_20)
      expect(reqs[1].target).to eq(peer_address_family)
    end
  end
end
