require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_peer_address_family).provider(:quagga) do
  describe 'instance' do
    it 'should have an instances method' do
      expect(described_class).to respond_to :instances
    end

    it 'should have a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  context 'running-config without default ipv4-unicast' do
    before :each do
      described_class.expects(:vtysh).with(
          '-c', 'show running-config'
      ).returns '!
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
 neighbor 1a03:d000:20a0::91 remote-as 31113
 neighbor 1a03:d000:20a0::91 update-source 1a03:d000:20a0::92
 maximum-paths 4
 maximum-paths ibgp 4
!
 address-family ipv6
 network 1a04:6d40::/48
 neighbor 1a03:d000:20a0::91 activate
 neighbor 1a03:d000:20a0::91 allowas-in 1
 exit-address-family
!
end'
    end

    it 'should return 5 resources' do
      expect(described_class.instances.size).to eq(5)
    end

    it 'should return the \'INTERNAL ipv4_unicast\' resource' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        :activate => :true,
        :address_family => :ipv4_unicast,
        :allow_as_in => 1,
        :default_originate => :false,
        :ensure => :present,
        :next_hop_self => :true,
        :peer => 'INTERNAL',
        :peer_group => :true,
        :prefix_list_in => :absent,
        :prefix_list_out => :absent,
        :provider => :quagga,
        :route_map_export => :absent,
        :route_map_import => :absent,
        :route_map_in => :absent,
        :route_map_out => :absent,
        :route_reflector_client => :false,
        :route_server_client => :false,
      })
    end

    it 'should return the \'RR ipv4_unicast\' resource' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
        :activate => :false,
        :address_family => :ipv4_unicast,
        :allow_as_in => :absent,
        :default_originate => :false,
        :ensure => :present,
        :next_hop_self => :true,
        :peer => 'RR',
        :peer_group => :true,
        :prefix_list_in => :absent,
        :prefix_list_out => :absent,
        :provider => :quagga,
        :route_map_export => :absent,
        :route_map_import => :absent,
        :route_map_in => :absent,
        :route_map_out => :absent,
        :route_reflector_client => :false,
        :route_server_client => :false,
      })
    end

    it 'should return the \'RR_WEAK ipv4_unicast\' resource' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
        :activate => :true,
        :address_family => :ipv4_unicast,
        :allow_as_in => :absent,
        :default_originate => :false,
        :ensure => :present,
        :next_hop_self => :true,
        :peer => 'RR_WEAK',
        :peer_group => :true,
        :prefix_list_in => :absent,
        :prefix_list_out => :absent,
        :provider => :quagga,
        :route_map_export => :absent,
        :route_map_import => :absent,
        :route_map_in => :absent,
        :route_map_out => 'RR_WEAK_out',
        :route_reflector_client => :false,
        :route_server_client => :false,
      })
    end

    it 'should return the \'172.16.32.108 ipv4_unicast\' resource' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq({
        :activate => :true,
        :address_family => :ipv4_unicast,
        :allow_as_in => :absent,
        :default_originate => :true,
        :ensure => :present,
        :next_hop_self => :false,
        :peer => '172.16.32.108',
        :peer_group => 'INTERNAL',
        :prefix_list_in => :absent,
        :prefix_list_out => :absent,
        :provider => :quagga,
        :route_map_export => :absent,
        :route_map_import => :absent,
        :route_map_in => :absent,
        :route_map_out => :absent,
        :route_reflector_client => :false,
        :route_server_client => :false,
      })
    end

    it 'should return the \'1a03:d000:20a0::91 ipv6_unicast\' resource' do
      expect(described_class.instances[4].instance_variable_get('@property_hash')).to eq({
        :activate => :true,
        :address_family => :ipv6_unicast,
        :allow_as_in => 1,
        :default_originate => :false,
        :ensure => :present,
        :next_hop_self => :false,
        :peer => '1a03:d000:20a0::91',
        :peer_group => :false,
        :prefix_list_in => :absent,
        :prefix_list_out => :absent,
        :provider => :quagga,
        :route_map_export => :absent,
        :route_map_import => :absent,
        :route_map_in => :absent,
        :route_map_out => :absent,
        :route_reflector_client => :false,
        :route_server_client => :false,
      })
    end
  end

  context 'running-config with default ipv4-unicast' do
    before :each do
      described_class.expects(:vtysh).with(
          '-c', 'show running-config'
      ).returns '!
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
 neighbor 1a03:d000:20a0::91 remote-as 31113
 neighbor 1a03:d000:20a0::91 update-source 1a03:d000:20a0::92
 maximum-paths 4
 maximum-paths ibgp 4
!
 address-family ipv6
 network 1a04:6d40::/48
 neighbor 1a03:d000:20a0::91 activate
 neighbor 1a03:d000:20a0::91 allowas-in 1
 exit-address-family
!
end'
    end

    it 'should return 5 resources' do
      expect(described_class.instances.size).to eq(5)
    end

    it 'should return the \'INTERNAL ipv4_unicast\' resource' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        :activate => :false,
        :address_family => :ipv4_unicast,
        :allow_as_in => 1,
        :default_originate => :false,
        :ensure => :present,
        :next_hop_self => :true,
        :peer => 'INTERNAL',
        :peer_group => :true,
        :prefix_list_in => :absent,
        :prefix_list_out => :absent,
        :provider => :quagga,
        :route_map_export => :absent,
        :route_map_import => :absent,
        :route_map_in => :absent,
        :route_map_out => :absent,
        :route_reflector_client => :false,
        :route_server_client => :false,
      })
    end

    it 'should return the \'RR ipv4_unicast\' resource' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
        :activate => :true,
        :address_family => :ipv4_unicast,
        :allow_as_in => :absent,
        :default_originate => :false,
        :ensure => :present,
        :next_hop_self => :true,
        :peer => 'RR',
        :peer_group => :true,
        :prefix_list_in => :absent,
        :prefix_list_out => :absent,
        :provider => :quagga,
        :route_map_export => :absent,
        :route_map_import => :absent,
        :route_map_in => :absent,
        :route_map_out => :absent,
        :route_reflector_client => :false,
        :route_server_client => :false,
      })
    end

    it 'should return the \'RR_WEAK ipv4_unicast\' resource' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
        :activate => :true,
        :address_family => :ipv4_unicast,
        :allow_as_in => :absent,
        :default_originate => :false,
        :ensure => :present,
        :next_hop_self => :true,
        :peer => 'RR_WEAK',
        :peer_group => :true,
        :prefix_list_in => :absent,
        :prefix_list_out => :absent,
        :provider => :quagga,
        :route_map_export => :absent,
        :route_map_import => :absent,
        :route_map_in => :absent,
        :route_map_out => 'RR_WEAK_out',
        :route_reflector_client => :false,
        :route_server_client => :false,
      })
    end

    it 'should return the \'172.16.32.108 ipv4_unicast\' resource' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq({
        :activate => :false,
        :address_family => :ipv4_unicast,
        :allow_as_in => :absent,
        :default_originate => :true,
        :ensure => :present,
        :next_hop_self => :false,
        :peer => '172.16.32.108',
        :peer_group => 'INTERNAL',
        :prefix_list_in => :absent,
        :prefix_list_out => :absent,
        :provider => :quagga,
        :route_map_export => :absent,
        :route_map_import => :absent,
        :route_map_in => :absent,
        :route_map_out => :absent,
        :route_reflector_client => :false,
        :route_server_client => :false,
      })
    end

    it 'should return the \'1a03:d000:20a0::91 ipv6_unicast\' resource' do
      expect(described_class.instances[4].instance_variable_get('@property_hash')).to eq({
        :activate => :true,
        :address_family => :ipv6_unicast,
        :allow_as_in => 1,
        :default_originate => :false,
        :ensure => :present,
        :next_hop_self => :false,
        :peer => '1a03:d000:20a0::91',
        :peer_group => :false,
        :prefix_list_in => :absent,
        :prefix_list_out => :absent,
        :provider => :quagga,
        :route_map_export => :absent,
        :route_map_import => :absent,
        :route_map_in => :absent,
        :route_map_out => :absent,
        :route_reflector_client => :false,
        :route_server_client => :false,
      })
    end
  end
end
