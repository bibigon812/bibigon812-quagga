require 'spec_helper'

describe Puppet::Type.type(:quagga_route_map).provider(:quagga) do
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
      ).and_return(
        <<~EOS,
        !
        route-map CONNECTED permit 500
         match ip address prefix-list CONNECTED_NETWORKS
        exit
        !
        route-map AS8631_out permit 10
         match origin igp
         set community 1:1 2:2 additive
         set extcommunity rt 100:1
         set metric +10
        exit
        !
        route-map AS8631_out permit 20
         match origin igp
         set community 0:6697 additive
        exit
        !
        route-map ANNOUNCE_ANYCAST permit 100
         match ip address prefix-list ANYCAST_ADDRESSES
        exit
        !
        route-map ANNOUNCE_ANYCAST deny 200
        exit
        route-map RECIEVE_ALL permit 100
        exit
        !
        end
        EOS
      )
    end

    it 'returns a resource for each instance' do
      expect(described_class.instances.size).to eq(6)
    end

    it 'returns the resource CONNECTED 500' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          action: :permit,
          name: 'CONNECTED 500',
          provider: :quagga,
          match: ['ip address prefix-list CONNECTED_NETWORKS'],
          on_match: :absent,
          set: [],
        },
      )
    end

    it 'returns the resource AS8631_out:10' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          action: :permit,
          name: 'AS8631_out 10',
          provider: :quagga,
          match: ['origin igp'],
          on_match: :absent,
          set: ['community 1:1 2:2 additive', 'extcommunity rt 100:1', 'metric +10'],
        },
      )
    end

    it 'returns the resource AS8631_out:20' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          action: :permit,
          name: 'AS8631_out 20',
          provider: :quagga,
          match: ['origin igp'],
          on_match: :absent,
          set: ['community 0:6697 additive'],
        },
      )
    end

    it 'returns the resource ANNOUNCE_ANYCAST:100' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          action: :permit,
          name: 'ANNOUNCE_ANYCAST 100',
          provider: :quagga,
          match: ['ip address prefix-list ANYCAST_ADDRESSES'],
          on_match: :absent,
          set: [],
        },
      )
    end

    it 'returns the resource ANNOUNCE_ANYCAST:200' do
      expect(described_class.instances[4].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          action: :deny,
          name: 'ANNOUNCE_ANYCAST 200',
          provider: :quagga,
          match: [],
          on_match: :absent,
          set: [],
        },
      )
    end

    it 'returns the resource RECIEVE_ALL:100' do
      expect(described_class.instances[5].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          action: :permit,
          name: 'RECIEVE_ALL 100',
          provider: :quagga,
          match: [],
          on_match: :absent,
          set: [],
        },
      )
    end
  end
end
