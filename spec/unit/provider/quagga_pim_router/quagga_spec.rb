require 'spec_helper'

describe Puppet::Type.type(:quagga_pim_router).provider(:quagga) do
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
hostname router-1.sandbox.local
!
ip forwarding
ipv6 forwarding
!
ip multicast-routing
!
line vty
!
end'
    end

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(1)
    end

    it 'should return the resource `quagga_pim_router`' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        :name => 'pim',
        :ip_multicast_routing => :true
      })
    end
  end
end
