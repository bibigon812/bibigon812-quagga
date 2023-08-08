require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_community_list).provider(:quagga) do
  before :each do
    allow(described_class).to receive(:commands).with(:vtysh).and_return('/usr/bin/vtysh')
  end

  let(:resource) do
    Puppet::Type.type(:quagga_bgp_community_list).new(
      provider: provider,
      title: '100',
    )
  end

  let(:provider) do
    described_class.new(
      ensure: :present,
      name: '100',
      provider: :quagga,
      rules: ['permit 65000:101', 'permit 65000:102', 'permit 65000:103'],
    )
  end

  let(:output) do
    '!
ip as-path access-list FROM_AS200 permit _200$
ip as-path access-list THROUGH_AS300 permit _300_
!
ip community-list 100 permit 65000:31133
ip community-list 300 permit 65000:50952
ip community-list 300 permit 65000:31500
ip community-list 300 permit 65000:6939
ip community-list 500 permit 65000:8359
ip community-list 500 permit 65000:12695
ip community-list 501 permit 64513:2_.*_64515:1
!
end
!'
  end

  describe 'instances' do
    it 'has an instance method' do
      expect(described_class).to respond_to :instances
    end
  end

  describe 'prefetch' do
    it 'has a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  context 'running-config' do
    before :each do
      expect(described_class).to receive(:vtysh).with(
        '-c', 'show running-config'
      ).and_return(output)
    end

    it 'returns a resource' do
      expect(described_class.instances.size).to eq(4)
    end

    it 'returns the resource community-list for instance 0' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          name: '100',
          provider: :quagga,
          rules: ['permit 65000:31133'],
        },
      )
    end

    it 'returns the resource community-list for instance 1' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          name: '300',
          provider: :quagga,
          rules: ['permit 65000:50952', 'permit 65000:31500', 'permit 65000:6939'],
        },
      )
    end

    it 'returns the resource community-list for instance 2' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          name: '500',
          provider: :quagga,
          rules: ['permit 65000:8359', 'permit 65000:12695'],
        },
      )
    end

    it 'returns the resource community-list for instance 3' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          name: '501',
          provider: :quagga,
          rules: ['permit 64513:2_.*_64515:1'],
        },
      )
    end
  end

  describe 'prefetch' do
    let(:resources) do
      {
        '100' => resource
      }
    end

    before :each do
      allow(described_class).to receive(:vtysh).with(
          '-c', 'show running-config'
        ).and_return(output)
    end

    it 'finds provider for resource' do
      described_class.prefetch(resources)
      expect(resources.values.first.provider).to eq(described_class.instances[0])
    end
  end

  describe '#create' do
    before(:each) do
      allow(provider).to receive(:exists?).and_return(false)
    end

    it 'has all rules' do
      resource[:ensure] = :present
      resource[:rules] = ['permit 65000:101', 'permit 65000:102', 'permit 65000:103']
      expect(provider).to receive(:vtysh).with(
        [
          '-c', 'configure terminal',
          '-c', 'ip community-list 100 permit 65000:101',
          '-c', 'ip community-list 100 permit 65000:102',
          '-c', 'ip community-list 100 permit 65000:103',
          '-c', 'end',
          '-c', 'write memory'
        ],
      )
      provider.create
    end
  end

  describe '#destroy' do
    before(:each) do
      allow(provider).to receive(:exists?).and_return(true)
    end

    it 'has all rules' do
      resource[:ensure] = :present
      resource[:rules] = ['permit 65000:101', 'permit 65000:102', 'permit 65000:103']
      expect(provider).to receive(:vtysh).with(
        [
          '-c', 'configure terminal',
          '-c', 'no ip community-list 100',
          '-c', 'end',
          '-c', 'write memory'
        ],
      )
      provider.destroy
    end
  end
end
