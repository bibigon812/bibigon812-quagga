require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_address_family).provider(:quagga) do
  before :each do
    allow(described_class).to receive(:commands).with(:vtysh).and_return('/usr/bin/vtysh')
  end

  let(:resource) do
    Puppet::Type.type(:quagga_bgp_address_family).new(
      provider: provider,
      title: :ipv4_unicast,
    )
  end

  let(:provider) do
    described_class.new(
      aggregate_address: ['192.168.0.0/24 summary-only', '10.0.0.0/24'],
      maximum_ebgp_paths: 2,
      maximum_ibgp_paths: 10,
      name: 'ipv4_unicast',
      networks: ['10.0.0.0/8', '192.168.0.0/16'],
      redistribute: [
        'connected',
        'ospf metric 30 route-map OSPF_BGP',
      ],
    )
  end

  let(:output) do
    '!
router bgp 197888
 bgp router-id 172.16.32.103
 no bgp default ipv4-unicast
 bgp graceful-restart stalepath-time 300
 bgp graceful-restart restart-time 300
 bgp network import-check
 network 172.16.32.0/24
 neighbor INTERNAL peer-group
 neighbor INTERNAL remote-as 197888
 neighbor INTERNAL allowas-in 1
 neighbor INTERNAL update-source 172.16.32.103
 neighbor INTERNAL activate
 neighbor INTERNAL next-hop-self
 neighbor INTERNAL soft-reconfiguration inbound
 neighbor RR peer-group
 neighbor RR remote-as 197888
 neighbor RR update-source 172.16.32.103
 neighbor RR activate
 neighbor RR next-hop-self
 neighbor RR_WEAK peer-group
 neighbor RR_WEAK remote-as 197888
 neighbor RR_WEAK update-source 172.16.32.103
 neighbor RR_WEAK activate
 neighbor RR_WEAK next-hop-self
 neighbor RR_WEAK route-map RR_WEAK_out out
 neighbor 172.16.32.108 peer-group INTERNAL
 neighbor 172.16.32.108 default-originate
 neighbor 172.16.32.108 shutdown
 neighbor 1a03:d000:20a0::91 remote-as 31113
 neighbor 1a03:d000:20a0::91 update-source 1a03:d000:20a0::92
 maximum-paths 4
 maximum-paths ibgp 4
!
 address-family ipv6
 network 1a04:6d40::/48
 neighbor 1a03:d000:20a0::91 activate
 neighbor 1a03:d000:20a0::91 allowas-in 1
 redistribute connected
 exit-address-family
!
end'
  end

  describe 'instance' do
    it 'has an instances method' do
      expect(described_class).to respond_to :instances
    end

    it 'has a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  context 'running-config without default ipv4-unicast' do
    before(:each) do
      expect(described_class).to receive(:vtysh).with(
          '-c', 'show running-config'
        ).and_return(output)
    end

    it 'returns a resource' do
      expect(described_class.instances.size).to eq(2)
    end

    it 'returns the :ipv4_unicast resource' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq(
        {
          aggregate_address: [],
          ensure: :present,
          maximum_ebgp_paths: 4,
          maximum_ibgp_paths: 4,
          name: 'ipv4_unicast',
          networks: ['172.16.32.0/24'],
          provider: :quagga,
          redistribute: [],
        },
      )
    end

    it 'returns the :ipv6_unicast resource' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq(
        {
          aggregate_address: [],
          ensure: :present,
          maximum_ebgp_paths: 1,
          maximum_ibgp_paths: 1,
          name: 'ipv6_unicast',
          networks: ['1a04:6d40::/48'],
          provider: :quagga,
          redistribute: [
            'connected',
          ],
        },
      )
    end
  end

  describe 'prefetch' do
    let(:resources) do
      {
        'ipv4_unicast' => resource
      }
    end

    before(:each) do
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
      allow(provider).to receive(:get_as_number).and_return(65_000)
    end

    it 'has all values' do
      resource[:ensure] = :present
      resource[:aggregate_address] = ['192.168.0.0/24 summary-only', '10.0.0.0/24']
      resource[:maximum_ebgp_paths] = 2
      resource[:maximum_ibgp_paths] = 10
      resource[:networks] = ['10.0.0.0/8', '192.168.0.0/16']
      resource[:redistribute] = [
        'connected',
        'ospf metric 30 route-map OSPF_BGP',
      ]
      expect(provider).to receive(:vtysh).with([
                                      '-c', 'configure terminal',
                                      '-c', 'router bgp 65000',
                                      '-c', 'address-family ipv4 unicast',
                                      '-c', 'aggregate-address 192.168.0.0/24 summary-only',
                                      '-c', 'aggregate-address 10.0.0.0/24',
                                      '-c', 'maximum-paths 2',
                                      '-c', 'maximum-paths ibgp 10',
                                      '-c', 'network 10.0.0.0/8',
                                      '-c', 'network 192.168.0.0/16',
                                      '-c', 'redistribute connected',
                                      '-c', 'redistribute ospf metric 30 route-map OSPF_BGP',
                                      '-c', 'end',
                                      '-c', 'write memory'
                                    ])
      provider.create
    end
  end

  describe '#destroy' do
    before(:each) do
      allow(provider).to receive(:exists?).and_return(true)
      allow(provider).to receive(:get_as_number).and_return(65_000)
    end

    it 'has all values' do
      resource[:ensure] = :present
      # These entries cannot be set here - they have to be part of the
      # initialization
      expect(provider).to receive(:vtysh).with([
                                      '-c', 'configure terminal',
                                      '-c', 'router bgp 65000',
                                      '-c', 'address-family ipv4 unicast',
                                      '-c', 'no aggregate-address 192.168.0.0/24 summary-only',
                                      '-c', 'no aggregate-address 10.0.0.0/24',
                                      '-c', 'no maximum-paths 2',
                                      '-c', 'no maximum-paths ibgp 10',
                                      '-c', 'no network 10.0.0.0/8',
                                      '-c', 'no network 192.168.0.0/16',
                                      '-c', 'no redistribute connected',
                                      '-c', 'no redistribute ospf metric 30 route-map OSPF_BGP',
                                      '-c', 'end',
                                      '-c', 'write memory'
                                    ])
      provider.destroy
    end
  end

  describe '#flush' do
    before(:each) do
      allow(provider).to receive(:exists?).and_return(true)
      allow(provider).to receive(:get_as_number).and_return(65_000)
    end

    it 'has all values' do
      resource[:ensure] = :present
      provider.aggregate_address = ['172.16.0.0/24', '192.168.0.0/24 summary-only']
      provider.maximum_ebgp_paths = 5
      provider.maximum_ibgp_paths = 8
      provider.networks = ['172.16.0.0/12', '192.168.0.0/16']
      provider.redistribute = ['ospf metric 30 route-map OSPF_BGP', 'kernel route-map KERNEL_BGP']
      expect(provider).to receive(:vtysh).with([
                                      '-c', 'configure terminal',
                                      '-c', 'router bgp 65000',
                                      '-c', 'address-family ipv4 unicast',
                                      '-c', 'no aggregate-address 10.0.0.0/24',
                                      '-c', 'aggregate-address 172.16.0.0/24',
                                      '-c', 'maximum-paths 5',
                                      '-c', 'maximum-paths ibgp 8',
                                      '-c', 'no network 10.0.0.0/8',
                                      '-c', 'network 172.16.0.0/12',
                                      '-c', 'no redistribute connected',
                                      '-c', 'redistribute kernel route-map KERNEL_BGP',
                                      '-c', 'end',
                                      '-c', 'write memory'
                                    ])
      provider.flush
    end
  end
end
