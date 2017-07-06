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

  before :each do
    Puppet::Type.type(:quagga_bgp_peer_address_family).stubs(:defaultprovider).returns providerclass
  end

  it "should have :proto, :type be it's namevar" do
    expect(described_class.key_attributes).to eq([:name, :address_family])
  end

  describe 'when validating attributes' do
    [:name, :address_family, :provider,].each do |param|
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

  describe 'title' do
    # it 'should support \'INTERNAL ipv4_unicast\' as a value' do
    #   described_class.stubs(:catalog).returns([quagga_bgp_router])
    #   expect { described_class.new(:title => 'INTERNAL ipv4_unicast') }.to_not raise_error
    # end

    it 'should support \'INTERNAL ipv6_unicast\' as a value' do
      expect { described_class.new(:title => 'INTERNAL ipv6_unicast') }.to_not raise_error
    end

    it 'should support \'INTERNAL ipv4_multicast\' as a value' do
      expect { described_class.new(:title => 'INTERNAL ipv4_multicast') }.to_not raise_error
    end

    # it 'should support \'INTERNAL\' as a value' do
    #   expect { described_class.new(:title => 'INTERNAL') }.to_not raise_error
    # end

    it 'should not support \'INTERNAL ipv6_foo\' as a value' do
      expect { described_class.new(:title => 'INTERNAL ipv6_foo') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support \'INTERNAL ipv6\' as a value' do
      expect { described_class.new(:title => 'INTERNAL ipv6') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end
end
