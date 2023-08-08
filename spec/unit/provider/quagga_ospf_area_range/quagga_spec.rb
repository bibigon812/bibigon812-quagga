require 'spec_helper'

describe Puppet::Type.type(:quagga_ospf_area_range).provider(:quagga) do
  let(:config) do
    '!
router ospf
 ospf router-id 172.16.32.103
 log-adjacency-changes
 network 172.16.32.0/24 area 0.0.0.0
 network 192.168.0.0/24 area 0.0.0.0
 area 0.0.0.21 range 1.1.2.0/24
 area 0.0.0.21 range 1.1.1.1/32 cost 100 not-advertise substitute 1.1.1.0/24
!'
  end

  let(:provider) do
    described_class.new(
      advertise: :false,
      cost: 100,
      ensure: :present,
      provider: :quagga,
      name: '0.0.0.21 1.1.1.1/32',
      substitute: '1.1.1.0/24',
    )
  end

  describe 'instance methods' do
    it 'has the instances method' do
      expect(described_class).to respond_to :instances
    end

    it 'has the prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  context 'running-config' do
    describe 'instances' do
      before(:each) do
        expect(described_class).to receive(:vtysh).with('-c', 'show running-config').and_return(config)
      end

      it 'returns resources' do
        expect(described_class.instances.size).to eq(2)
      end

      it "returns range '0.0.0.21 1.1.2.0/24'" do
        expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq(
          {
            advertise: :true,
            cost: :absent,
            ensure: :present,
            provider: :quagga,
            name: '0.0.0.21 1.1.2.0/24',
            substitute: :absent,
          },
        )
      end

      it "returns range '0.0.0.21 1.1.1.1/32'" do
        expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq(
          {
            advertise: :false,
            cost: 100,
            ensure: :present,
            provider: :quagga,
            name: '0.0.0.21 1.1.1.1/32',
            substitute: '1.1.1.0/24',
          },
        )
      end
    end

    describe 'prefetch' do
      before :each do
        allow(described_class).to receive(:vtysh).with('-c', 'show running-config').and_return config
      end

      let(:resources) do
        {
          '0.0.0.21 1.1.1.1/32' => Puppet::Type.type(:quagga_ospf_area_range).new(
            title: '0.0.0.21 1.1.1.1/32',
            provider: provider,
          )
        }
      end

      it 'finds provider for resource' do
        described_class.prefetch(resources)
        expect(resources.values.first.provider).to eq(described_class.instances[1])
      end
    end
  end

  context "with range '0.0.0.21 1.1.1.1/32'" do
    let(:resource) do
      Puppet::Type.type(:quagga_ospf_area_range).new(
        provider: provider,
        substitute: '1.1.1.0/24',
        title: '0.0.0.21 1.1.1.1/32',
      )
    end

    describe '#create' do
      before :each do
        allow(provider).to receive(:exists?).and_return(false)
      end

      it do
        resource[:ensure] = :present
        expect(provider).to receive(:vtysh).with(
          [
            '-c', 'configure terminal',
            '-c', 'router ospf',
            '-c', 'area 0.0.0.21 range 1.1.1.1/32 substitute 1.1.1.0/24',
            '-c', 'end',
            '-c', 'write memory'
          ],
        )
        provider.create
      end
    end

    describe '#destroy' do
      before :each do
        allow(provider).to receive(:exists?).and_return(true)
      end

      it do
        resource[:ensure] = :present
        expect(provider).to receive(:vtysh).with(
          [
            '-c', 'configure terminal',
            '-c', 'router ospf',
            '-c', 'no area 0.0.0.21 range 1.1.1.1/32',
            '-c', 'end',
            '-c', 'write memory'
          ],
        )
        provider.destroy
      end
    end
  end
end
