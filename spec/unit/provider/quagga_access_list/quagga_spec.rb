require 'spec_helper'

describe Puppet::Type.type(:quagga_access_list).provider(:quagga) do
  before :each do
    described_class.stubs(:commands).with(:vtysh).returns('/usr/bin/vtysh')
  end

  let(:resource) do
    Puppet::Type.type(:quagga_access_list).new(
      provider: provider,
      title: '1',
    )
  end

  let(:provider) do
    described_class.new(
      ensure:   :present,
      number:   '1',
      provider: :quagga,
      rules:    ['permit host 127.0.0.1', 'deny any'],
    )
  end

  let(:output) do
    '!
access-list 1 remark IP Standard access list
access-list 1 permit 127.0.0.1
access-list 1 deny any
access-list 100 remark IP Extended access list
access-list 100 permit 192.168.0.0 0.0.0.255 any
access-list 100 deny any any
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
      described_class.expects(:vtysh).with(
        '-c', 'show running-config'
      ).returns output
    end

    it 'returns a resource' do
      expect(described_class.instances.size).to eq(2)
    end

    it 'returns the resource standard access-list' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
                                                                                           ensure:   :present,
        name:     '1',
        provider: :quagga,
        remark:   'IP Standard access list',
        rules:    ['permit 127.0.0.1', 'deny any'],
                                                                                         })
    end

    it 'returns the resource extended access-list' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
                                                                                           ensure:   :present,
        name:     '100',
        provider: :quagga,
        remark:   'IP Extended access list',
        rules:    ['permit 192.168.0.0 0.0.0.255 any', 'deny any any'],
                                                                                         })
    end
  end

  describe 'prefetch' do
    let(:resources) do
      {
        '1' => resource
      }
    end

    before :each do
      described_class.stubs(:vtysh).with(
          '-c', 'show running-config'
        ).returns output
    end

    it 'finds provider for resource' do
      described_class.prefetch(resources)
      expect(resources.values.first.provider).to eq(described_class.instances[0])
    end
  end
end
