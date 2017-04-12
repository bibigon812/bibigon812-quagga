require 'spec_helper'

describe Puppet::Type.type(:ospf_interface).provider(:quagga) do
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

  context 'with three interfaces' do
    before :each do
      described_class.expects(:vtysh).with(
        '-c', 'show ip ospf interface'
      ).returns 'lo is up
  ifindex 1, MTU 65536 bytes, BW 0 Kbit <UP,LOOPBACK,RUNNING>
  OSPF not enabled on this interface
tun0 is up
  ifindex 45, MTU 1476 bytes, BW 0 Kbit <UP,POINTOPOINT,RUNNING,NOARP>
  OSPF not enabled on this interface
tun1 is up
  ifindex 44, MTU 1476 bytes, BW 0 Kbit <UP,POINTOPOINT,RUNNING,NOARP>
  Internet Address 10.255.8.49/30, Area 0.0.0.0
  MTU mismatch detection:disabled
  Router ID 91.228.177.2, Network Type BROADCAST, Cost: 100
  Transmit Delay is 1 sec, State Backup, Priority 100
  Designated Router (ID) 10.255.78.1, Interface Address 10.255.8.50
  Backup Designated Router (ID) 91.228.177.2, Interface Address 10.255.8.49
  Multicast group memberships: OSPFAllRouters OSPFDesignatedRouters
  Timer intervals configured, Hello 2s, Dead 8s, Wait 8s, Retransmit 4
    Hello due in 0.584s
  Neighbor Count is 1, Adjacent neighbor count is 1'
    end

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(1)
    end

    it 'should return the resource tun1' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        :ensure => :present,
        :name => 'tun1',
        :provider => :quagga,
        :cost => 100,
        :dead_interval => 8,
        :hello_interval => 2,
        :mtu_ignore => :true,
        :network => :broadcast,
        :priority => 100,
        :retransmit_interval => 4,
        :transmit_delay => 1,
      })
    end
  end
end
