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
        '-c', 'show running-config'
      ).returns 'interface eth0
!
interface eth1
 ip ospf hello-interval 2
 ip ospf dead-interval 8
 ip ospf priority 50
 ip ospf retransmit-interval 4
 ip ospf mtu-ignore
!
interface gre0
!
interface gretap0
!
interface ip_vti0
!
interface lo
!
interface tun0
!'
    end

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(7)
    end

    it 'should return the resource eth0' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        :ensure => :present,
        :name => 'eth0',
        :provider => :quagga,
        :cost => 10,
        :dead_interval => 40,
        :hello_interval => 10,
        :mtu_ignore => :disabled,
        :network => :broadcast,
        :priority => 1,
        :retransmit_interval => 5,
        :transmit_delay => 1,
      })
    end

    it 'should return the resource eth1' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
         :ensure => :present,
         :name => 'eth1',
         :provider => :quagga,
         :cost => 10,
         :dead_interval => 8,
         :hello_interval => 2,
         :mtu_ignore => :enabled,
         :network => :broadcast,
         :priority => 50,
         :retransmit_interval => 4,
         :transmit_delay => 1,
      })
    end
  end
end
