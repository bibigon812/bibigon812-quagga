require 'spec_helper'

describe Puppet::Type.type(:redistribution).provider(:quagga) do
  describe 'instances' do
    it 'should have an instance method' do
      expect(described_class).to respond_to :instances
    end
  end

  describe 'prefetch' do
    it 'should have a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  context 'running-config' do
    before :each do
      described_class.expects(:vtysh).with(
        '-c', 'show running-config'
      ).returns '!
router bgp 197888
 bgp router-id 172.16.32.103
 bgp network import-check
 network 91.228.177.0/24
 redistribute connected metric 100 route-map ABCD
 neighbor INTERNAL peer-group
 neighbor INTERNAL remote-as 197888
 neighbor INTERNAL update-source 172.16.32.103
 neighbor INTERNAL next-hop-self
 neighbor INTERNAL soft-reconfiguration inbound
 neighbor INTERNAL allowas-in 1
 neighbor RR peer-group
 neighbor RR remote-as 197888
 neighbor RR update-source 172.16.32.103
 neighbor RR next-hop-self
 neighbor RR_WEAK peer-group
 neighbor RR_WEAK remote-as 197888
 neighbor RR_WEAK update-source 172.16.32.103
 neighbor RR_WEAK next-hop-self
 neighbor RR_WEAK route-map RR_WEAK_out out
 neighbor 172.16.32.108 peer-group INTERNAL
 neighbor 172.16.32.108 shutdown
 maximum-paths 4
 maximum-paths ibgp 4
!
 address-family ipv6
 exit-address-family
 exit
!
router ospf
 default-information originate always metric 100 metric-type 1 route-map ABCD
 ospf router-id 10.255.78.4
 redistribute kernel route-map KERNEL
 redistribute connected route-map CONNECTED
 redistribute static route-map STATIC
 redistribute rip route-map RIP
 network 10.255.1.0/24 area 0.0.15.211
!
ip route 0.0.0.0/0 10.255.1.2 254
!
ip prefix-list ADVERTISED-PREFIXES seq 10 permit 193.160.158.0/26
ip prefix-list CONNECTED-NETWORKS seq 20 permit 193.160.158.96/28 le 32'
    end

    it 'should return 5 resources' do
      expect(described_class.instances.size).to eq(5)
    end

    it 'should return the first resource' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        :ensure => :present,
        :name => 'bgp:197888:connected',
        :provider => :quagga,
        :metric => 100,
        :route_map => 'ABCD',
      })
    end

    it 'should return the first resource' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
        :ensure => :present,
        :name => 'ospf::kernel',
        :provider => :quagga,
        :route_map => 'KERNEL',
      })
    end

    it 'should return the first resource' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
        :ensure => :present,
        :name => 'ospf::connected',
        :provider => :quagga,
        :route_map => 'CONNECTED',
      })
    end

    it 'should return the first resource' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq({
        :ensure => :present,
        :name => 'ospf::static',
        :provider => :quagga,
        :route_map => 'STATIC',
      })
    end

    it 'should return the first resource' do
      expect(described_class.instances[4].instance_variable_get('@property_hash')).to eq({
        :ensure => :present,
        :name => 'ospf::rip',
        :provider => :quagga,
        :route_map => 'RIP',
      })
    end
  end
end
