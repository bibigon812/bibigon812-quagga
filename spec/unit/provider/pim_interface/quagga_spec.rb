require 'spec_helper'

describe Puppet::Type.type(:pim_interface).provider(:quagga) do
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
 ip pim ssm
 ip igmp
 ip igmp query-interval 150
 ip igmp query-max-response-time-dsec 200
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
        :pim_ssm => :false,
        :igmp => :false,
        :igmp_query_interval => 125,
        :igmp_query_max_response_time_dsec => 100
      })
    end

    it 'should return the resource eth1' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
         :ensure => :present,
         :name => 'eth1',
         :provider => :quagga,
         :pim_ssm => :true,
         :igmp => :true,
         :igmp_query_interval => 150,
         :igmp_query_max_response_time_dsec => 200
      })
    end
  end
end
