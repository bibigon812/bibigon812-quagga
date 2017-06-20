require 'spec_helper'

describe Puppet::Type.type(:quagga_route_map).provider(:quagga) do
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
route-map CONNECTED permit 500
 match ip address prefix-list CONNECTED_NETWORKS
!
route-map AS8631_out permit 10
 match origin igp
 set community 1:1 2:2 additive
 set extcommunity rt 100:1
 set metric +10
!
route-map AS8631_out permit 20
 match origin igp
 set community 0:6697 additive
!'
    end

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(3)
    end

    it 'should return the resource CONNECTED:500' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
          :ensure => :present,
          :action => :permit,
          :name => 'CONNECTED:500',
          :provider => :quagga,
          :match => ['ip address prefix-list CONNECTED_NETWORKS',],
          :on_match => :absent,
          :set => [],
      })
    end

    it 'should return the resource AS8631_out:10' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
          :ensure => :present,
          :action => :permit,
          :name => 'AS8631_out:10',
          :provider => :quagga,
          :match => ['origin igp',],
          :on_match => :absent,
          :set => ['community 1:1 2:2 additive', 'extcommunity rt 100:1', 'metric +10',],
      })
    end

    it 'should return the resource AS8631_out:20' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
          :ensure => :present,
          :action => :permit,
          :name => 'AS8631_out:20',
          :provider => :quagga,
          :match => ['origin igp',],
          :on_match => :absent,
          :set => ['community 0:6697 additive',],
      })
    end
  end
end
