require 'spec_helper'

describe Puppet::Type.type(:quagga_community_list).provider(:quagga) do
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
      ).returns 'ip as-path access-list FROM_AS200 permit _200$
ip as-path access-list THROUGH_AS300 permit _300_
!
ip community-list 100 permit 65000:31133
ip community-list 300 permit 65000:50952
ip community-list 300 permit 65000:31500
ip community-list 300 permit 65000:6939
ip community-list 500 permit 65000:8359
ip community-list 500 permit 65000:12695
end'
    end

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(3)
    end

    it 'should return the resource community-list' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
          :ensure => :present,
          :name => '100',
          :provider => :quagga,
          :rules => ['permit 65000:31133',],
      })
    end

    it 'should return the resource community-list' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
          :ensure => :present,
          :name => '300',
          :provider => :quagga,
          :rules => ['permit 65000:50952', 'permit 65000:31500', 'permit 65000:6939',],
      })
    end

    it 'should return the resource community-list' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
          :ensure => :present,
          :name => '500',
          :provider => :quagga,
          :rules => ['permit 65000:8359', 'permit 65000:12695',],
      })
    end
  end
end
