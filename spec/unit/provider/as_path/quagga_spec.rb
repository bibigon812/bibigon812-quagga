require 'spec_helper'

describe Puppet::Type.type(:as_path).provider(:quagga) do
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

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(10)
    end

    it 'should return the resource ospf' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
          :ensure => :present,
          :name => 'FROM_AS100:permit:_100$ _100_',
          :provider => :quagga,
      })
    end
  end
end
