require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_as_path).provider(:quagga) do
  before :each do
    described_class.stubs(:commands).with(:vtysh).returns('/usr/bin/vtysh')
  end

  let(:resource) do
    Puppet::Type.type(:quagga_bgp_as_path).new(
      :provider => provider,
      :title    => 'FROM_AS100',
    )
  end

  let(:provider) do
    described_class.new(
      :ensure   => :present,
      :name     => 'FROM_AS100',
      :provider => :quagga,
      :rules    => ['permit _100$ _100_', 'permit _90_', 'permit _90$',],
    )
  end

  let(:output) do
    '!
ip as-path access-list FROM_AS100 permit _100$ _100_
ip as-path access-list FROM_AS100 permit _90_
ip as-path access-list FROM_AS100 permit _90$
ip as-path access-list FROM_AS20764 permit _20764$
ip as-path access-list FROM_AS23352 permit _23352$
ip as-path access-list FROM_AS25184 permit _25184$
ip as-path access-list FROM_AS44397 permit _44397$
ip as-path access-list FROM_AS53813 permit _53813$
ip as-path access-list FROM_AS55720 permit _55720$
ip as-path access-list THROUGH_AS6697 permit _6697_
!'
  end

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
      ).returns output
    end

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(8)
    end

    it 'should return the resource ospf' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
          :ensure   => :present,
          :name     => 'FROM_AS100',
          :provider => :quagga,
          :rules    => ['permit _100$', 'permit _100_', 'permit _90_', 'permit _90$',],
      })
    end

    it 'should return the resource ospf' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
          :ensure   => :present,
          :name     => 'FROM_AS20764',
          :provider => :quagga,
          :rules    => ['permit _20764$',],
      })
    end
  end

  describe 'prefetch' do
    let(:resources) do
      {
        'FROM_AS100' => resource
      }
    end

    before :each do
      described_class.stubs(:vtysh).with(
          '-c', 'show running-config'
      ).returns output
    end

    it 'should find provider for resource' do
      described_class.prefetch(resources)
      expect(resources.values.first.provider).to eq(described_class.instances[0])
    end
  end

  describe '#create' do
    before do
      provider.stubs(:exists?).returns(false)
    end

    it 'should has all rules' do
      resource[:ensure] = :present
      resource[:rules] = ['permit _100$', 'permit _100_',]
      provider.expects(:vtysh).with([
        '-c', 'configure terminal',
        '-c', 'ip as-path access-list FROM_AS100 permit _100$',
        '-c', 'ip as-path access-list FROM_AS100 permit _100_',
        '-c', 'end',
        '-c', 'write memory',
      ])
      provider.create
    end
  end

  describe '#destroy' do
    before do
      provider.stubs(:exists?).returns(true)
    end

    it 'should has all rules' do
      resource[:ensure] = :present
      resource[:rules] = ['permit _100$', 'permit _100_',]
      provider.expects(:vtysh).with([
        '-c', 'configure terminal',
        '-c', 'no ip as-path access-list FROM_AS100',
        '-c', 'end',
        '-c', 'write memory',
      ])
      provider.destroy
    end
  end
end
