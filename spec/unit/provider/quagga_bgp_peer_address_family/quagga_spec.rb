require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_peer_address_family).provider(:quagga) do
  let(:resource) do
    Puppet::Type.type(:quagga_bgp_peer_address_family).new(
      provider: provider,
      name: '2001:db8:: ipv6_unicast',
    )
  end

  let(:provider) do
    described_class.new(
    activate: :true,
    allow_as_in: 1,
    default_originate: :true,
    ensure: :present,
    name: '2001:db8:: ipv6_unicast',
    next_hop_self: :true,
    peer_group: :false,
    prefix_list_in: 'PREFIX_LIST_IN',
    prefix_list_out: 'PREFIX_LIST_OUT',
    provider: :quagga,
    route_map_export: 'ROUTE_MAP_EXPORT',
    route_map_import: 'ROUTE_MAP_IMPORT',
    route_map_in: 'ROUTE_MAP_IN',
    route_map_out: 'ROUTE_MAP_OUT',
    route_reflector_client: :true,
    route_server_client: :true,
  )
  end

  let(:provider1) do
    described_class.new(
    activate: :false,
    allow_as_in: :absent,
    default_originate: :false,
    ensure: :present,
    name: '2001:db8:: ipv6_unicast',
    next_hop_self: :false,
    peer_group: 'INTERNAL',
    prefix_list_in: :absent,
    prefix_list_out: :absent,
    provider: :quagga,
    route_map_export: :absent,
    route_map_import: :absent,
    route_map_in: :absent,
    route_map_out: :absent,
    route_reflector_client: :false,
    route_server_client: :false,
  )
  end

  let(:output_wo_default_ipv4_unicast) do
    '!
router bgp 197888
 bgp router-id 172.16.32.103
 no bgp default ipv4-unicast
 bgp graceful-restart stalepath-time 300
 bgp graceful-restart restart-time 300
 bgp network import-check
 network 172.16.32.0/24
 neighbor INTERNAL peer-group
 neighbor INTERNAL remote-as 197888
 neighbor INTERNAL allowas-in 1
 neighbor INTERNAL update-source 172.16.32.103
 neighbor INTERNAL activate
 neighbor INTERNAL next-hop-self
 neighbor INTERNAL soft-reconfiguration inbound
 neighbor RR peer-group
 neighbor RR remote-as 197888
 neighbor RR update-source 172.16.32.103
 no neighbor RR activate
 neighbor RR next-hop-self
 neighbor RR_WEAK peer-group
 neighbor RR_WEAK remote-as 197888
 neighbor RR_WEAK update-source 172.16.32.103
 neighbor RR_WEAK activate
 neighbor RR_WEAK next-hop-self
 neighbor RR_WEAK route-map RR_WEAK_out out
 neighbor 172.16.32.108 peer-group INTERNAL
 neighbor 172.16.32.108 default-originate
 neighbor 172.16.32.108 shutdown
 neighbor 2001:db8:: remote-as 31113
 neighbor 2001:db8:: update-source 1a03:d000:20a0::92
 maximum-paths 4
 maximum-paths ibgp 4
!
 address-family ipv6
 network 1a04:6d40::/48
 neighbor 2001:db8:: activate
 neighbor 2001:db8:: allowas-in 1
 exit-address-family
!
end'
  end

  let(:output_w_default_ipv4_unicast) do
    '!
router bgp 65000
 bgp router-id 172.16.32.103
 bgp graceful-restart stalepath-time 300
 bgp graceful-restart restart-time 300
 bgp network import-check
 network 172.16.32.0/24
 neighbor INTERNAL peer-group
 neighbor INTERNAL remote-as 65000
 no neighbor INTERNAL activate
 neighbor INTERNAL allowas-in 1
 neighbor INTERNAL update-source 172.16.32.103
 neighbor INTERNAL next-hop-self
 neighbor INTERNAL soft-reconfiguration inbound
 neighbor RR peer-group
 neighbor RR remote-as 65000
 neighbor RR update-source 172.16.32.103
 neighbor RR next-hop-self
 neighbor RR_WEAK peer-group
 neighbor RR_WEAK remote-as 65000
 neighbor RR_WEAK update-source 172.16.32.103
 neighbor RR_WEAK next-hop-self
 neighbor RR_WEAK route-map RR_WEAK_out out
 neighbor 172.16.32.108 peer-group INTERNAL
 neighbor 172.16.32.108 default-originate
 neighbor 172.16.32.108 shutdown
 neighbor 2001:db8:: remote-as 31113
 neighbor 2001:db8:: update-source 1a03:d000:20a0::92
 maximum-paths 4
 maximum-paths ibgp 4
!
 address-family ipv6
 network 1a04:6d40::/48
 neighbor 2001:db8:: activate
 neighbor 2001:db8:: allowas-in 1
 exit-address-family
!
end'
  end

  describe 'instance' do
    it 'has an instances method' do
      expect(described_class).to respond_to :instances
    end

    it 'has a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  context 'running-config without default ipv4-unicast' do
    before :each do
      expect(described_class).to receive(:vtysh).with(
          '-c', 'show running-config'
        ).and_return(output_wo_default_ipv4_unicast)
    end

    it 'returns 5 resources' do
      expect(described_class.instances.size).to eq(5)
    end

    it 'returns the \'INTERNAL ipv4_unicast\' resource' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq(
        {
          activate: :true,
          allow_as_in: 1,
          default_originate: :false,
          ensure: :present,
          name: 'INTERNAL ipv4_unicast',
          next_hop_self: :true,
          peer_group: :true,
          prefix_list_in: :absent,
          prefix_list_out: :absent,
          provider: :quagga,
          route_map_export: :absent,
          route_map_import: :absent,
          route_map_in: :absent,
          route_map_out: :absent,
          route_reflector_client: :false,
          route_server_client: :false,
        },
      )
    end

    it 'returns the \'RR ipv4_unicast\' resource' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq(
        {
          activate: :false,
          allow_as_in: :absent,
          default_originate: :false,
          ensure: :present,
          name: 'RR ipv4_unicast',
          next_hop_self: :true,
          peer_group: :true,
          prefix_list_in: :absent,
          prefix_list_out: :absent,
          provider: :quagga,
          route_map_export: :absent,
          route_map_import: :absent,
          route_map_in: :absent,
          route_map_out: :absent,
          route_reflector_client: :false,
          route_server_client: :false,
        },
      )
    end

    it 'returns the \'RR_WEAK ipv4_unicast\' resource' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq(
        {
          activate: :true,
          allow_as_in: :absent,
          default_originate: :false,
          ensure: :present,
          name: 'RR_WEAK ipv4_unicast',
          next_hop_self: :true,
          peer_group: :true,
          prefix_list_in: :absent,
          prefix_list_out: :absent,
          provider: :quagga,
          route_map_export: :absent,
          route_map_import: :absent,
          route_map_in: :absent,
          route_map_out: 'RR_WEAK_out',
          route_reflector_client: :false,
          route_server_client: :false,
        },
      )
    end

    it 'returns the \'172.16.32.108 ipv4_unicast\' resource' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq(
        {
          activate: :false,
          allow_as_in: :absent,
          default_originate: :true,
          ensure: :present,
          name: '172.16.32.108 ipv4_unicast',
          next_hop_self: :false,
          peer_group: 'INTERNAL',
          prefix_list_in: :absent,
          prefix_list_out: :absent,
          provider: :quagga,
          route_map_export: :absent,
          route_map_import: :absent,
          route_map_in: :absent,
          route_map_out: :absent,
          route_reflector_client: :false,
          route_server_client: :false,
        },
      )
    end

    it 'returns the \'2001:db8:: ipv6_unicast\' resource' do
      expect(described_class.instances[4].instance_variable_get('@property_hash')).to eq(
        {
          activate: :true,
          allow_as_in: 1,
          default_originate: :false,
          ensure: :present,
          name: '2001:db8:: ipv6_unicast',
          next_hop_self: :false,
          peer_group: :false,
          prefix_list_in: :absent,
          prefix_list_out: :absent,
          provider: :quagga,
          route_map_export: :absent,
          route_map_import: :absent,
          route_map_in: :absent,
          route_map_out: :absent,
          route_reflector_client: :false,
          route_server_client: :false,
        },
      )
    end
  end

  context 'running-config with default ipv4-unicast' do
    before :each do
      expect(described_class).to receive(:vtysh).with(
          '-c', 'show running-config'
        ).and_return(output_w_default_ipv4_unicast)
    end

    it 'returns 5 resources' do
      expect(described_class.instances.size).to eq(5)
    end

    it 'returns the \'INTERNAL ipv4_unicast\' resource' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq(
        {
          activate: :false,
          allow_as_in: 1,
          default_originate: :false,
          ensure: :present,
          name: 'INTERNAL ipv4_unicast',
          next_hop_self: :true,
          peer_group: :true,
          prefix_list_in: :absent,
          prefix_list_out: :absent,
          provider: :quagga,
          route_map_export: :absent,
          route_map_import: :absent,
          route_map_in: :absent,
          route_map_out: :absent,
          route_reflector_client: :false,
          route_server_client: :false,
        },
      )
    end

    it 'returns the \'RR ipv4_unicast\' resource' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq(
        {
          activate: :false,
          allow_as_in: :absent,
          default_originate: :false,
          ensure: :present,
          name: 'RR ipv4_unicast',
          next_hop_self: :true,
          peer_group: :true,
          prefix_list_in: :absent,
          prefix_list_out: :absent,
          provider: :quagga,
          route_map_export: :absent,
          route_map_import: :absent,
          route_map_in: :absent,
          route_map_out: :absent,
          route_reflector_client: :false,
          route_server_client: :false,
        },
      )
    end

    it 'returns the \'RR_WEAK ipv4_unicast\' resource' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq(
        {
          activate: :false,
          allow_as_in: :absent,
          default_originate: :false,
          ensure: :present,
          name: 'RR_WEAK ipv4_unicast',
          next_hop_self: :true,
          peer_group: :true,
          prefix_list_in: :absent,
          prefix_list_out: :absent,
          provider: :quagga,
          route_map_export: :absent,
          route_map_import: :absent,
          route_map_in: :absent,
          route_map_out: 'RR_WEAK_out',
          route_reflector_client: :false,
          route_server_client: :false,
        },
      )
    end

    it 'returns the \'172.16.32.108 ipv4_unicast\' resource' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq(
        {
          activate: :false,
          allow_as_in: :absent,
          default_originate: :true,
          ensure: :present,
          name: '172.16.32.108 ipv4_unicast',
          next_hop_self: :false,
          peer_group: 'INTERNAL',
          prefix_list_in: :absent,
          prefix_list_out: :absent,
          provider: :quagga,
          route_map_export: :absent,
          route_map_import: :absent,
          route_map_in: :absent,
          route_map_out: :absent,
          route_reflector_client: :false,
          route_server_client: :false,
        },
      )
    end

    it 'returns the \'2001:db8:: ipv6_unicast\' resource' do
      expect(described_class.instances[4].instance_variable_get('@property_hash')).to eq(
        {
          activate: :true,
          allow_as_in: 1,
          default_originate: :false,
          ensure: :present,
          name: '2001:db8:: ipv6_unicast',
          next_hop_self: :false,
          peer_group: :false,
          prefix_list_in: :absent,
          prefix_list_out: :absent,
          provider: :quagga,
          route_map_export: :absent,
          route_map_import: :absent,
          route_map_in: :absent,
          route_map_out: :absent,
          route_reflector_client: :false,
          route_server_client: :false,
        },
      )
    end
  end

  describe 'prefetch' do
    let(:resources) do
      {
        'INTERNAL ipv4_multicast' => resource
      }
    end

    before :each do
      allow(described_class).to receive(:vtysh).with(
          '-c', 'show running-config'
        ).and_return output_wo_default_ipv4_unicast
    end

    it 'finds provider for resource' do
      described_class.prefetch(resources)
      expect(resources.values.first.provider).to eq(described_class.instances[0])
    end
  end

  describe '#create' do
    before(:each) do
      allow(provider).to receive(:exists?).and_return(false)
      allow(provider).to receive(:get_as_number).and_return(65_000)
    end

    it 'has all values' do
      resource[:activate]               = :true
      resource[:allow_as_in]            = 1
      resource[:default_originate]      = :true
      resource[:ensure]                 = :present
      resource[:next_hop_self]          = :true
      resource[:name]                   = '2001:db8:: ipv6_unicast'
      resource[:peer_group]             = :false
      resource[:prefix_list_in]         = 'PREFIX_LIST_IN'
      resource[:prefix_list_out]        = 'PREFIX_LIST_OUT'
      resource[:route_map_export]       = 'ROUTE_MAP_EXPORT'
      resource[:route_map_import]       = 'ROUTE_MAP_IMPORT'
      resource[:route_map_in]           = 'ROUTE_MAP_IN'
      resource[:route_map_out]          = 'ROUTE_MAP_OUT'
      resource[:route_reflector_client] = :true
      resource[:route_server_client]    = :true
      expect(provider).to receive(:vtysh).with(
        [
          '-c', 'configure terminal',
          '-c', 'router bgp 65000',
          '-c', 'address-family ipv6',
          '-c', 'neighbor 2001:db8:: activate',
          '-c', 'neighbor 2001:db8:: allowas-in 1',
          '-c', 'neighbor 2001:db8:: default-originate',
          '-c', 'neighbor 2001:db8:: next-hop-self',
          '-c', 'neighbor 2001:db8:: prefix-list PREFIX_LIST_IN in',
          '-c', 'neighbor 2001:db8:: prefix-list PREFIX_LIST_OUT out',
          '-c', 'neighbor 2001:db8:: route-map ROUTE_MAP_EXPORT export',
          '-c', 'neighbor 2001:db8:: route-map ROUTE_MAP_IMPORT import',
          '-c', 'neighbor 2001:db8:: route-map ROUTE_MAP_IN in',
          '-c', 'neighbor 2001:db8:: route-map ROUTE_MAP_OUT out',
          '-c', 'neighbor 2001:db8:: route-reflector-client',
          '-c', 'neighbor 2001:db8:: route-server-client',
          '-c', 'end',
          '-c', 'write memory'
        ],
      )
      provider.create
    end

    it 'has `activate`' do
      resource[:activate]               = :true
      resource[:ensure]                 = :present
      expect(provider).to receive(:vtysh).with(
        [
          '-c', 'configure terminal',
          '-c', 'router bgp 65000',
          '-c', 'address-family ipv6',
          '-c', 'neighbor 2001:db8:: activate',
          '-c', 'end',
          '-c', 'write memory'
        ],
      )
      provider.create
    end
  end

  describe '#destroy' do
    before(:each) do
      allow(provider).to receive(:exists?).and_return(true)
      allow(provider).to receive(:get_as_number).and_return(65_000)
      allow(provider1).to receive(:exists?).and_return(true)
      allow(provider1).to receive(:get_as_number).and_return(65_000)
    end

    it 'has all values' do
      expect(provider).to receive(:vtysh).with(
        [
          '-c', 'configure terminal',
          '-c', 'router bgp 65000',
          '-c', 'address-family ipv6',
          '-c', 'no neighbor 2001:db8:: activate',
          '-c', 'no neighbor 2001:db8:: allowas-in',
          '-c', 'no neighbor 2001:db8:: default-originate',
          '-c', 'no neighbor 2001:db8:: next-hop-self',
          '-c', 'no neighbor 2001:db8:: prefix-list PREFIX_LIST_IN in',
          '-c', 'no neighbor 2001:db8:: prefix-list PREFIX_LIST_OUT out',
          '-c', 'no neighbor 2001:db8:: route-map ROUTE_MAP_EXPORT export',
          '-c', 'no neighbor 2001:db8:: route-map ROUTE_MAP_IMPORT import',
          '-c', 'no neighbor 2001:db8:: route-map ROUTE_MAP_IN in',
          '-c', 'no neighbor 2001:db8:: route-map ROUTE_MAP_OUT out',
          '-c', 'no neighbor 2001:db8:: route-reflector-client',
          '-c', 'no neighbor 2001:db8:: route-server-client',
          '-c', 'end',
          '-c', 'write memory'
        ],
      )
      provider.destroy
    end

    it 'removes peer-group' do
      expect(provider1).to receive(:vtysh).with(
        [
          '-c', 'configure terminal',
          '-c', 'router bgp 65000',
          '-c', 'address-family ipv6',
          '-c', 'no neighbor 2001:db8:: peer-group INTERNAL',
          '-c', 'no neighbor 2001:db8:: activate',
          '-c', 'end',
          '-c', 'write memory'
        ],
      )
      provider1.destroy
    end
  end

  describe '#flush' do
    before(:each) do
      allow(provider).to receive(:exists?).and_return(true)
      allow(provider).to receive(:get_as_number).and_return(65_000)
    end

    it 'updates all values except `activate`' do
      resource[:ensure] = :present
      provider.peer_group             = 'INTERNAL'
      provider.activate               = :true
      provider.allow_as_in            = :absent
      provider.default_originate      = :false
      provider.next_hop_self          = :false
      provider.prefix_list_in         = :absent
      provider.prefix_list_out        = :absent
      provider.route_map_export       = :absent
      provider.route_map_import       = :absent
      provider.route_map_in           = :absent
      provider.route_map_out          = :absent
      provider.route_reflector_client = :false
      provider.route_server_client    = :false
      expect(provider).to receive(:vtysh).with(
        [
          '-c', 'configure terminal',
          '-c', 'router bgp 65000',
          '-c', 'address-family ipv6',
          '-c', 'neighbor 2001:db8:: peer-group INTERNAL',
          '-c', 'neighbor 2001:db8:: activate',
          '-c', 'no neighbor 2001:db8:: allowas-in',
          '-c', 'no neighbor 2001:db8:: default-originate',
          '-c', 'no neighbor 2001:db8:: next-hop-self',
          '-c', 'no neighbor 2001:db8:: prefix-list PREFIX_LIST_IN in',
          '-c', 'no neighbor 2001:db8:: prefix-list PREFIX_LIST_OUT out',
          '-c', 'no neighbor 2001:db8:: route-map ROUTE_MAP_EXPORT export',
          '-c', 'no neighbor 2001:db8:: route-map ROUTE_MAP_IMPORT import',
          '-c', 'no neighbor 2001:db8:: route-map ROUTE_MAP_IN in',
          '-c', 'no neighbor 2001:db8:: route-map ROUTE_MAP_OUT out',
          '-c', 'no neighbor 2001:db8:: route-reflector-client',
          '-c', 'no neighbor 2001:db8:: route-server-client',
          '-c', 'end',
          '-c', 'write memory'
        ],
      )
      provider.flush
    end
  end
end
