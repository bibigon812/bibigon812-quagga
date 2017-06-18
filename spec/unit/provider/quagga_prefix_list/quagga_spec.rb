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
ip prefix-list ADVERTISED_ROUTES seq 10 permit 91.228.177.0/24
ip prefix-list ADVERTISED_ROUTES seq 1000 deny 0.0.0.0/0 le 32
ip prefix-list AS_LOCAL seq 10 permit 91.228.177.0/24
ip prefix-list DEFAULT_ROUTE seq 10 permit 0.0.0.0/0
ip prefix-list SPBTV_EKT seq 10 permit 185.36.226.0/24
ip prefix-list SPBTV_KRD seq 10 permit 185.36.224.0/24
ip prefix-list SPBTV_KRS seq 10 permit 185.36.225.0/24
ip prefix-list SPBTV_KZN seq 10 permit 89.232.64.0/18
ip prefix-list SPBTV_NSK seq 10 permit 212.192.232.0/23
ip prefix-list SPBTV_RND seq 10 permit 212.192.236.0/23
ip prefix-list SPBTV_SAM seq 10 permit 213.178.48.0/20
ip prefix-list SPBTV_SPB seq 10 permit 193.160.158.0/24 ge 25 le 31
!
ip as-path access-list AS100 permit _100$
ip as-path access-list AS100 permit _100_
ip as-path access-list FROM_AS200 permit _200$
ip as-path access-list THROUGH_AS300 permit _300_
!'
    end

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(13)
    end

    it 'should return the resource ABCD:5' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
          :ensure => :present,
          :name => 'ABCD:5',
          :provider => :quagga,
          :action => :permit,
          :prefix => 'any',
          :proto => :ip,
      })
    end

    it 'should return the resource ADVERTISED_ROUTES:10' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
          :ensure => :present,
          :name => 'ADVERTISED_ROUTES:10',
          :provider => :quagga,
          :action => :permit,
          :prefix => '91.228.177.0/24',
          :proto => :ip,
      })
    end
  end
end
