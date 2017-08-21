require 'spec_helper'

describe Puppet::Type.type(:quagga_static_route).provider(:quagga) do
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
ip route 10.0.0.0/8 10.1.2.1 blackhole
ip route 10.0.0.0/8 10.1.1.1
ip route 10.0.0.0/8 Null0 250
!
line vty
!
end'
    end

    it 'should return a resource' do
      expect(described_class.instances.size).to eq(3)
    end

    it 'should return the resource `quagga_statis_route`' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        distance: :absent,
        ensure: :present,
        nexthop: '10.1.2.1',
        option: :blackhole,
        prefix: '10.0.0.0/8',
        provider: :quagga,
      })
    end

    it 'should return the resource `quagga_statis_route`' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
        distance: :absent,
        ensure: :present,
        nexthop: '10.1.1.1',
        option: :absent,
        prefix: '10.0.0.0/8',
        provider: :quagga,
      })
    end

    it 'should return the resource `quagga_statis_route`' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
        distance: 250,
        ensure: :present,
        nexthop: 'Null0',
        option: :absent,
        prefix: '10.0.0.0/8',
        provider: :quagga,
      })
    end
  end

  let(:provider) do
    described_class.new(
        ensure:   :present,
        provider: :iproute2,
    )
  end

  let(:catalog) { Puppet::Resource::Catalog.new }

  describe 'prefetch' do
    before :each do
      described_class.stubs(:vtysh).with('-c', 'show running-config').
          returns <<-EOS
ip route 172.16.3.0/24 Null0
ip route 172.16.3.0/24 172.16.0.4
ip route 172.16.3.0/24 172.16.0.5 blackhole
ip route 172.16.3.0/24 172.16.0.6 250
EOS
    end

    context 'network_route \'172.16.3.0/24\'' do
      let(:resources) do
        hash = {}
          %w{Null0 172.16.0.4 172.16.0.5 172.16.0.6}.each do |nexthop|
            hash["172.16.3.0/24 #{nexthop}"] = Puppet::Type.type(:quagga_static_route).new(title: "172.16.3.0/24 #{nexthop}")
          end
        hash
      end

      it 'with nexthop ' do
        described_class.prefetch(resources)
        expect(resources['172.16.3.0/24 Null0'].provider.prefix).to eq('172.16.3.0/24')
        expect(resources['172.16.3.0/24 Null0'].provider.nexthop).to eq('Null0')
        expect(resources['172.16.3.0/24 Null0'].provider.distance).to eq(:absent)
        expect(resources['172.16.3.0/24 Null0'].provider.option).to eq(:absent)

        expect(resources['172.16.3.0/24 172.16.0.4'].provider.prefix).to eq('172.16.3.0/24')
        expect(resources['172.16.3.0/24 172.16.0.4'].provider.nexthop).to eq('172.16.0.4')
        expect(resources['172.16.3.0/24 172.16.0.4'].provider.distance).to eq(:absent)
        expect(resources['172.16.3.0/24 172.16.0.4'].provider.option).to eq(:absent)

        expect(resources['172.16.3.0/24 172.16.0.5'].provider.prefix).to eq('172.16.3.0/24')
        expect(resources['172.16.3.0/24 172.16.0.5'].provider.nexthop).to eq('172.16.0.5')
        expect(resources['172.16.3.0/24 172.16.0.5'].provider.distance).to eq(:absent)
        expect(resources['172.16.3.0/24 172.16.0.5'].provider.option).to eq(:blackhole)

        expect(resources['172.16.3.0/24 172.16.0.6'].provider.prefix).to eq('172.16.3.0/24')
        expect(resources['172.16.3.0/24 172.16.0.6'].provider.nexthop).to eq('172.16.0.6')
        expect(resources['172.16.3.0/24 172.16.0.6'].provider.distance).to eq(250)
        expect(resources['172.16.3.0/24 172.16.0.6'].provider.option).to eq(:absent)
      end
    end
  end
end
