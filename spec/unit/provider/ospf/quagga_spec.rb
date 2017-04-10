require 'spec_helper'

describe Puppet::Type.type(:ospf).provider(:quagga) do
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
 address-family ipv6
 network 2a04:6d40:1:ffff::/64
 exit-address-family
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

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(1)
    end

    it 'should return the resource ospf' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        :default_information => 'originate always metric 100 metric-type 1 route-map ABCD',
        :ensure => :present,
        :name => :ospf,
        :network => [
          '10.255.1.0/24 area 0.0.15.211',
        ],
        :provider => :quagga,
        :redistribute => [
          'connected route-map CONNECTED',
          'kernel route-map KERNEL',
          'rip route-map RIP',
          'static route-map STATIC',
        ],
        :router_id => "10.255.78.4",
      })
    end
    #
    # it 'should return the resource tun0' do
    #   expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
    #     :ensure => :disabled,
    #     :name => 'tun0',
    #     :provider => :quagga,
    #   })
    # end
    #
    # it 'should return the resource tun1' do
    #   expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
    #     :ensure => :enabled,
    #     :name => 'tun1',
    #     :provider => :quagga,
    #     :cost => 100,
    #     :dead_interval => 8,
    #     :hello_interval => 2,
    #     :mtu_ignore => :true,
    #     :network_type => :broadcast,
    #     :priority => 100,
    #     :retransmit_interval => 4,
    #     :transmit_delay => 1,
    #   })
    # end
  end
end
