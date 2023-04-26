require 'spec_helper'

describe Puppet::Type.type(:quagga_global).provider(:quagga) do
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
        <<~EOS
        !
        hostname router-1.sandbox.local
        !
        ip forwarding
        ipv6 forwarding
        !
        line vty
        !
        end
        EOS
      )
    end

    it 'returns a resource' do
      expect(described_class.instances.size).to eq(1)
    end

    it 'returns the resource `quagga_system`' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
                                                                                           name: 'router-1.sandbox.local',
        hostname: 'router-1.sandbox.local',
        ip_forwarding: :true,
        ipv6_forwarding: :true,
        password: :absent,
        enable_password: :absent,
        line_vty: :true,
        service_password_encryption: :false,
                                                                                         })
    end
  end
end
