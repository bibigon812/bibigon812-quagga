require 'spec_helper'

describe Puppet::Type.type(:quagga_ospf_interface).provider(:quagga) do
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

  context 'with three interfaces' do
    before :each do
      expect(described_class).to receive(:vtysh).with(
        '-c', 'show running-config'
      ).and_return(
        <<~EOS
        interface eth0
        !
        interface eth1
         ip ospf authentication message-digest
         ip ospf message-digest-key 1 md5 hello123
         ip ospf cost 10
         ip ospf hello-interval 2
         ip ospf dead-interval 8
         ip ospf priority 50
         ip ospf retransmit-interval 4
         ip ospf mtu-ignore
         ip ospf network broadcast
         ip pim ssm
         ip igmp
         ip igmp query-interval 150
         ip igmp query-max-response-time-dsec 200
        !
        !
        interface gre0
        !
        interface gretap0
        !
        interface ip_vti0
        !
        interface lo
        !
        interface tun0
        !
        EOS
      )
    end

    it 'returns a resource' do
      expect(described_class.instances.size).to eq(7)
    end

    it 'returns the resource eth0' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
                                                                                           name: 'eth0',
        provider: :quagga,
        auth: :absent,
        message_digest_key: :absent,
        cost: :absent,
        dead_interval: 40,
        hello_interval: 10,
        mtu_ignore: :false,
        network: :absent,
        priority: 1,
        retransmit_interval: 5,
        transmit_delay: 1,
                                                                                         })
    end

    it 'returns the resource eth1' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
                                                                                           name: 'eth1',
        provider: :quagga,
        auth: 'message-digest',
        message_digest_key: '1 md5 hello123',
        cost: 10,
        dead_interval: 8,
        hello_interval: 2,
        mtu_ignore: :true,
        network: 'broadcast',
        priority: 50,
        retransmit_interval: 4,
        transmit_delay: 1,
                                                                                         })
    end
  end
end
