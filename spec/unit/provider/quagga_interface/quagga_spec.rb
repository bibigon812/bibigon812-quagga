require 'spec_helper'

describe Puppet::Type.type(:quagga_interface).provider(:quagga) do
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
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 hello123
 ip ospf cost 10
 ip ospf hello-interval 2
 ip ospf dead-interval 8
 ip ospf priority 50
 ip ospf retransmit-interval 4
 ip ospf mtu-ignore
 ip pim ssm
 ip igmp
 ip igmp query-interval 150
 ip igmp query-max-response-time-dsec 200
!
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
        :bandwidth => :absent,
        :ensure => :present,
        :name => 'eth0',
        :provider => :quagga,
        :description => :absent,
        :enable => :true,
        :ip_address => [],
        :link_detect => :false,
        :multicast => :false,
        :ospf_auth => :absent,
        :ospf_message_digest_key => :absent,
        :ospf_cost => :absent,
        :ospf_dead_interval => 40,
        :ospf_hello_interval => 10,
        :ospf_mtu_ignore => :false,
        :ospf_network => 'broadcast',
        :ospf_priority => 1,
        :ospf_retransmit_interval => 5,
        :ospf_transmit_delay => 1,
        :pim_ssm => :false,
        :igmp => :false,
        :igmp_query_interval => 125,
        :igmp_query_max_response_time_dsec => 100
      })
    end

    it 'should return the resource eth1' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
        :bandwidth => :absent,
        :ensure => :present,
        :name => 'eth1',
        :provider => :quagga,
        :description => :absent,
        :enable => :true,
        :ip_address => [],
        :link_detect => :false,
        :multicast => :false,
        :ospf_auth => 'message-digest',
        :ospf_message_digest_key => '1 md5 hello123',
        :ospf_cost => 10,
        :ospf_dead_interval => 8,
        :ospf_hello_interval => 2,
        :ospf_mtu_ignore => :true,
        :ospf_network => 'broadcast',
        :ospf_priority => 50,
        :ospf_retransmit_interval => 4,
        :ospf_transmit_delay => 1,
        :pim_ssm => :true,
        :igmp => :true,
        :igmp_query_interval => 150,
        :igmp_query_max_response_time_dsec => 200
      })
    end
  end
end
