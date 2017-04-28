require 'spec_helper'

describe Puppet::Type.type(:ospf_area).provider(:quagga) do
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
 network 195.131.0.0/24
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
 area 0.0.15.211 default-cost 100
 area 0.10.10.10 export-list ACCESS_LIST_EXPORT
 area 0.10.10.10 import-list ACCESS_LIST_IPMORT
 area 0.10.10.10 filter-list prefix PREFIX_LIST_IMPORT in
 area 0.10.10.10 filter-list prefix PREFIX_LIST_EXPORT out
 area 0.10.10.10 stub
 default-information originate always metric 100 metric-type 1 route-map ABCD
 ospf router-id 10.255.78.4
 redistribute kernel route-map KERNEL
 redistribute connected route-map CONNECTED
 redistribute static route-map STATIC
 redistribute rip route-map RIP
 network 10.255.1.0/24 area 0.0.15.211
 network 10.255.2.0/24 area 0.0.15.211
 network 10.255.3.0/24 area 0.0.15.211
 network 192.168.1.0/24 area 0.10.10.10
 network 192.168.2.0/24 area 0.10.10.10
!
ip route 0.0.0.0/0 10.255.1.2 254
!
ip prefix-list ADVERTISED-PREFIXES seq 10 permit 195.131.0.0/16
ip prefix-list CONNECTED-NETWORKS seq 20 permit 195.131.0.0/28 le 32'
    end

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(2)
    end

    it 'should return the first resource' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        :default_cost => 100,
        :ensure => :present,
        :name => '0.0.15.211',
        :networks => [ '10.255.1.0/24', '10.255.2.0/24', '10.255.3.0/24' ],
        :provider => :quagga,
        :shortcut => :default,
        :stub => :disable,
      })
    end

    it 'should return the second resource' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
        :access_list_export => 'ACCESS_LIST_EXPORT',
        :access_list_import => 'ACCESS_LIST_IPMORT',
        :ensure => :present,
        :name => '0.10.10.10',
        :networks => [ '192.168.1.0/24', '192.168.2.0/24' ],
        :prefix_list_export => 'PREFIX_LIST_EXPORT',
        :prefix_list_import => 'PREFIX_LIST_IMPORT',
        :provider => :quagga,
        :shortcut => :default,
        :stub => :enable,
      })
    end
  end
end
