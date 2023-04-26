require 'spec_helper'

describe Puppet::Type.type(:quagga_ospf_router).provider(:quagga) do
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
    before(:each) do
      expect(described_class).to receive(:vtysh).with(
        '-c', 'show running-config'
      ).and_return(
        <<~EOS
        !
         address-family ipv6
         network 2a04:6d40:1:ffff::/64
         exit-address-family
        !
        router ospf
         default-information originate always metric 100 metric-type 1 route-map ABCD
         ospf router-id 10.255.78.4
         passive-interface eth0
         passive-interface eth1 1.1.1.1
         passive-interface default
         redistribute kernel route-map KERNEL
         redistribute connected route-map CONNECTED
         redistribute static route-map STATIC
         redistribute rip route-map RIP
         network 10.255.1.0/24 area 0.0.15.211
         distribute-list QEWR out static
         distribute-list QWER out isis
        !
        ip route 0.0.0.0/0 10.255.1.2 254
        !
        ip prefix-list ADVERTISED-PREFIXES seq 10 permit 195.131.0.0/16
        ip prefix-list CONNECTED-NETWORKS seq 20 permit 195.131.0.0/28 le 32
        EOS
      )
    end

    it 'returns a resource' do
      expect(described_class.instances.size).to eq(1)
    end

    it 'returns the resource ospf' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
                                                                                           abr_type: :cisco,
        default_originate: 'always metric 100 metric-type 1 route-map ABCD',
        ensure: :present,
        name: 'ospf',
        opaque: :false,
        passive_interfaces: [
          'eth0',
          'eth1 1.1.1.1',
          'default',
        ],
        redistribute: [
          'kernel route-map KERNEL',
          'connected route-map CONNECTED',
          'static route-map STATIC',
          'rip route-map RIP',
        ],
        rfc1583: :false,
        router_id: '10.255.78.4',
        log_adjacency_changes: :false,
        distribute_list: [
          'QEWR out static',
          'QWER out isis',
        ]
                                                                                         })
    end
  end

  context 'running-config without ospf' do
    before :each do
      expect(described_class).to receive(:vtysh).with(
          '-c', 'show running-config'
        ).and_return(
          <<~EOS
          !
           address-family ipv6
           network 2a04:6d40:1:ffff::/64
           exit-address-family
          !
          ip route 0.0.0.0/0 10.255.1.2 254
          !
          ip prefix-list ADVERTISED-PREFIXES seq 10 permit 195.131.0.0/16
          ip prefix-list CONNECTED-NETWORKS seq 20 permit 195.131.0.0/28 le 32
          EOS
        )
    end

    it 'does not return a resource' do
      expect(described_class.instances.size).to eq(0)
    end
  end
end
