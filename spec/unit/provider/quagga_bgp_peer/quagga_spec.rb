require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_peer).provider(:quagga) do
  describe 'instances' do
    it 'should have an instance method' do
      expect(described_class).to respond_to :instances
    end
  end

  describe 'methods' do
    it 'should have a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

#   before :each do
#     described_class.expects(:vtysh).with(
#       '-c', 'show ip bgp summary'
#     ).returns 'BGP router identifier 172.16.32.103, local AS number 65000
# RIB entries 1, using 112 bytes of memory
# Peers 4, using 18 KiB of memory
# Peer groups 3, using 96 bytes of memory'
#   end

  context 'running-config without default ipv4-unicast' do
    before :each do
      described_class.expects(:vtysh).with(
        '-c', 'show running-config'
      ).returns '!
router bgp 65000
 bgp router-id 172.16.32.103
 no bgp default ipv4-unicast
 bgp graceful-restart stalepath-time 300
 bgp graceful-restart restart-time 300
 bgp network import-check
 network 172.16.32.0/24
 neighbor INTERNAL peer-group
 neighbor INTERNAL remote-as 65000
 neighbor INTERNAL allowas-in 1
 neighbor INTERNAL update-source 172.16.32.103
 neighbor INTERNAL activate
 neighbor INTERNAL next-hop-self
 neighbor INTERNAL soft-reconfiguration inbound
 neighbor RR peer-group
 neighbor RR remote-as 65000
 neighbor RR update-source 172.16.32.103
 neighbor RR activate
 neighbor RR next-hop-self
 neighbor RR_WEAK peer-group
 neighbor RR_WEAK remote-as 65000
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

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(5)
    end

    it 'should return the INTERNAL resource' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        local_as: :absent,
        name: 'INTERNAL',
        passive: :false,
        peer_group: :true,
        provider: :quagga,
        remote_as: 65000,
        shutdown: :false,
        update_source: '172.16.32.103',
      })
    end

    it 'should return the RR resource' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        local_as: :absent,
        name: 'RR',
        passive: :false,
        peer_group: :true,
        provider: :quagga,
        remote_as: 65000,
        shutdown: :false,
        update_source: '172.16.32.103',
      })
    end

    it 'should return the RR_WEAK resource' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        local_as: :absent,
        name: 'RR_WEAK',
        passive: :false,
        peer_group: :true,
        provider: :quagga,
        remote_as: 65000,
        shutdown: :false,
        update_source: '172.16.32.103',
      })
    end

    it 'should return the 172.16.32.108 resource' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        local_as: :absent,
        name: '172.16.32.108',
        passive: :false,
        peer_group: 'INTERNAL',
        provider: :quagga,
        remote_as: :absent,
        shutdown: :true,
        update_source: :absent,
      })
    end

    it 'should return the 1a03:d000:20a0::91 resource' do
      expect(described_class.instances[4].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        local_as: :absent,
        name: '1a03:d000:20a0::91',
        passive: :false,
        peer_group: :false,
        provider: :quagga,
        remote_as: 31113,
        shutdown: :false,
        update_source: '1a03:d000:20a0::92',
      })
    end
  end

  context 'running-config without bgp' do
    before :each do
      described_class.expects(:vtysh).with(
          '-c', 'show running-config'
      ).returns '!
!'
    end

    it 'should not return a resource' do
      expect(described_class.instances.size).to eq(0)
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

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(5)
    end

    it 'should return the INTERNAL resource' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        local_as: :absent,
        name: 'INTERNAL',
        passive: :false,
        peer_group: :true,
        provider: :quagga,
        remote_as: 65000,
        shutdown: :false,
        update_source: '172.16.32.103',
      })
    end

    it 'should return the RR resource' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        local_as: :absent,
        name: 'RR',
        passive: :false,
        peer_group: :true,
        provider: :quagga,
        remote_as: 65000,
        shutdown: :false,
        update_source: '172.16.32.103',
      })
    end

    it 'should return the RR_WEAK resource' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        local_as: :absent,
        name: 'RR_WEAK',
        passive: :false,
        peer_group: :true,
        provider: :quagga,
        remote_as: 65000,
        shutdown: :false,
        update_source: '172.16.32.103',
      })
    end

    it 'should return the 172.16.32.108 resource' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        local_as: :absent,
        name: '172.16.32.108',
        passive: :false,
        peer_group: 'INTERNAL',
        provider: :quagga,
        remote_as: :absent,
        shutdown: :true,
        update_source: :absent,
      })
    end

    it 'should return the 1a03:d000:20a0::91 resource' do
      expect(described_class.instances[4].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        local_as: :absent,
        name: '1a03:d000:20a0::91',
        passive: :false,
        peer_group: :false,
        provider: :quagga,
        remote_as: 31113,
        shutdown: :false,
        update_source: '1a03:d000:20a0::92',
      })
    end
  end
end
