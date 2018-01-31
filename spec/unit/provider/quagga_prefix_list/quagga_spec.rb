require 'spec_helper'

describe Puppet::Type.type(:quagga_prefix_list).provider(:quagga) do
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
ip prefix-list ABCD seq 5 permit any
ip prefix-list ADVERTISED_ROUTES seq 10 permit 1.1.1.0/24
ip prefix-list ADVERTISED_ROUTES seq 1000 deny 0.0.0.0/0 le 32
ip prefix-list AS_LOCAL seq 10 permit 1.1.1.0/24
ip prefix-list DEFAULT_ROUTE seq 10 permit 0.0.0.0/0
!
ipv6 prefix-list ipv6_advertised_prefixes seq 10 permit 2001:db8::/48
!
ip as-path access-list AS100 permit _100$
ip as-path access-list AS100 permit _100_
ip as-path access-list FROM_AS200 permit _200$
ip as-path access-list THROUGH_AS300 permit _300_
!'
    end

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(6)
    end

    it 'should return the resource \'ABCD 5\'' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
          :ensure   => :present,
          :name     => 'ABCD 5',
          :ge       => :absent,
          :le       => :absent,
          :provider => :quagga,
          :action   => :permit,
          :prefix   => 'any',
          :proto    => :ip,
      })
    end

    it 'should return the resource \'ADVERTISED_ROUTES 10\'' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
          :ensure   => :present,
          :name     => 'ADVERTISED_ROUTES 10',
          :ge       => :absent,
          :le       => :absent,
          :provider => :quagga,
          :action   => :permit,
          :prefix   => '1.1.1.0/24',
          :proto    => :ip,
      })
    end

    it 'should return the resource \'ADVERTISED_ROUTES 1000\'' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
          :ensure   => :present,
          :name     => 'ADVERTISED_ROUTES 1000',
          :ge       => :absent,
          :le       => 32,
          :provider => :quagga,
          :action   => :deny,
          :prefix   => '0.0.0.0/0',
          :proto    => :ip,
      })
    end

    it 'should return the resource \'ipv6_advertised_prefixes\'' do
      expect(described_class.instances[5].instance_variable_get('@property_hash')).to eq({
          ensure: :present,
          name: 'ipv6_advertised_prefixes 10',
          ge: :absent,
          le: :absent,
          provider: :quagga,
          action: :permit,
          prefix: '2001:db8::/48',
          proto: :ipv6,
      })
    end
  end
end
