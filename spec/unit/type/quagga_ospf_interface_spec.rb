require 'spec_helper'

describe Puppet::Type.type(:quagga_ospf_interface) do
  let :providerclass do
    described_class.provide(:fake_quagga_provider) do
      attr_accessor :property_hash
      def create; end

      def destroy; end

      def exists?
        get(:ensure) == :present
      end
      mk_resource_methods
    end
  end

  let(:zebra) { Puppet::Type.type(:service).new(name: 'zebra') }
  let(:ospfd) { Puppet::Type.type(:service).new(name: 'ospfd') }
  let(:catalog) { Puppet::Resource::Catalog.new }

  before :each do
    described_class.stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_interface)
  end

  it 'has :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [ :auth, :message_digest_key, :cost, :dead_interval,
      :hello_interval, :mtu_ignore, :network,
      :priority, :retransmit_interval, :transmit_delay].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'auth' do
      it 'supports :absent as a value' do
        expect { described_class.new(name: 'foo', auth: :absent) }.not_to raise_error
      end

      it 'supports message-digest as a value' do
        expect { described_class.new(name: 'foo', auth: 'message-digest') }.not_to raise_error
      end

      it 'contains :message-digest' do
        expect(described_class.new(name: 'foo', auth: 'message-digest')[:auth]).to eq(:"message-digest")
      end

      it 'does not support foo as a value' do
        expect { described_class.new(name: 'foo', auth: :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end

    describe 'message_digest_key' do
      it 'supports :absent as a value' do
        expect { described_class.new(name: 'foo', message_digest_key: :absent) }.not_to raise_error
      end

      it 'supports "1 md5 hello123" as a value' do
        expect { described_class.new(name: 'foo', message_digest_key: '1 md5 hello123') }.not_to raise_error
      end

      it 'contains "1 md5 hello123"' do
        expect(described_class.new(name: 'foo', message_digest_key: '1 md5 hello123')[:message_digest_key]).to eq('1 md5 hello123')
      end

      it 'does not support foo as a value' do
        expect { described_class.new(name: 'foo', message_digest_key: :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end

    describe 'cost' do
      it 'supports :absent as a value' do
        expect { described_class.new(name: 'foo', cost: :absent) }.not_to raise_error
      end

      it 'supports 100 as a value' do
        expect { described_class.new(name: 'foo', cost: 100) }.not_to raise_error
      end

      it 'does not support 0 as a value' do
        expect { described_class.new(name: 'foo', cost: 0) }.to raise_error(Puppet::Error, %r{OSPF cost})
      end

      it 'does not support 65536 as a value' do
        expect { described_class.new(name: 'foo', cost: 65_536) }.to raise_error(Puppet::Error, %r{OSPF cost})
      end

      it 'contains 50' do
        expect(described_class.new(name: 'foo', cost: 50)[:cost]).to eq(50)
      end

      it 'contains 51' do
        expect { described_class.new(name: 'foo', cost: '51') }.to raise_error Puppet::Error, %r{OSPF cost}
      end
    end

    describe 'dead_interval' do
      it 'supports 100 as a value' do
        expect { described_class.new(name: 'foo', dead_interval: 100) }.not_to raise_error
      end

      it 'does not support 0 as a value' do
        expect { described_class.new(name: 'foo', dead_interval: 0) }.to raise_error Puppet::Error, %r{OSPF dead interval}
      end

      it 'does not support 65536 as a value' do
        expect { described_class.new(name: 'foo', dead_interval: 65_536) }.to raise_error Puppet::Error, %r{OSPF dead interval}
      end

      it 'contains 50' do
        expect(described_class.new(name: 'foo', dead_interval: 50)[:dead_interval]).to eq(50)
      end

      it 'contains 51' do
        expect { described_class.new(name: 'foo', dead_interval: '51') }.to raise_error Puppet::Error, %r{OSPF dead interval}
      end
    end

    describe 'hello_interval' do
      it 'supports 100 as a value' do
        expect { described_class.new(name: 'foo', hello_interval: 100) }.not_to raise_error
      end

      it 'does not support 0 as a value' do
        expect { described_class.new(name: 'foo', hello_interval: 0) }.to raise_error Puppet::Error, %r{OSPF hello packets interval}
      end

      it 'does not support 65536 as a value' do
        expect { described_class.new(name: 'foo', hello_interval: 65_536) }.to raise_error Puppet::Error, %r{OSPF hello packets interval}
      end

      it 'contains 50' do
        expect(described_class.new(name: 'foo', hello_interval: 50)[:hello_interval]).to eq(50)
      end

      it 'contains 51' do
        expect { described_class.new(name: 'foo', hello_interval: '51') }.to raise_error Puppet::Error, %r{OSPF hello packets interval}
      end
    end

    [:mtu_ignore].each do |property|
      describe property.to_s do
        it 'supports true as a value' do
          expect { described_class.new(name: 'foo', property => true) }.not_to raise_error
        end

        it 'supports :true as a value' do
          expect { described_class.new(name: 'foo', property => :true) }.not_to raise_error
        end

        it 'supports "true" as a value' do
          expect { described_class.new(name: 'foo', property => 'true') }.not_to raise_error
        end

        it 'supports false as a value' do
          expect { described_class.new(name: 'foo', property => false) }.not_to raise_error
        end

        it 'supports :false as a value' do
          expect { described_class.new(name: 'foo', property => :false) }.not_to raise_error
        end

        it 'supports "false" as a value' do
          expect { described_class.new(name: 'foo', property => 'false') }.not_to raise_error
        end

        it 'does not support foo as a value' do
          expect { described_class.new(name: 'foo', property => :disabled) }.to raise_error Puppet::Error, %r{Invalid value}
        end

        it 'contains enabled when passed string "true"' do
          expect(described_class.new(name: 'foo', property => 'true')[property]).to eq(:true)
        end

        it 'contains enabled when passed symbol :true' do
          expect(described_class.new(name: 'foo', property => :true)[property]).to eq(:true)
        end

        it 'contains enabled when passed value true' do
          expect(described_class.new(name: 'foo', property => true)[property]).to eq(:true)
        end

        it 'contains disabled when passed string "false"' do
          expect(described_class.new(name: 'foo', property => 'false')[property]).to eq(:false)
        end

        it 'contains disabled when passed symbol :false' do
          expect(described_class.new(name: 'foo', property => :false)[property]).to eq(:false)
        end

        it 'contains disabled when passed value false' do
          expect(described_class.new(name: 'foo', property => false)[property]).to eq(:false)
        end
      end
    end

    describe 'network' do
      it 'supports :broadcast as value' do
        expect { described_class.new(name: 'foo', network: 'broadcast') }.not_to raise_error
      end

      it 'supports non-broadcast as value' do
        expect { described_class.new(name: 'foo', network: 'non-broadcast') }.not_to raise_error
      end

      it 'supports point-to-multipoint as value' do
        expect { described_class.new(name: 'foo', network: 'point-to-multipoint') }.not_to raise_error
      end

      it 'supports point-to-point as value' do
        expect { described_class.new(name: 'foo', network: 'point-to-point') }.not_to raise_error
      end

      it 'supports :absent as value' do
        expect { described_class.new(name: 'foo', network: :absent) }.not_to raise_error
      end

      it 'contains point-to-point' do
        expect(described_class.new(name: 'foo', network: 'point-to-point')[:network]).to eq(:"point-to-point")
      end
    end

    describe 'priority' do
      it 'supports 100 as a value' do
        expect { described_class.new(name: 'foo', priority: 100) }.not_to raise_error
      end

      it 'does not support -1 as a value' do
        expect { described_class.new(name: 'foo', priority: -1) }.to raise_error(Puppet::Error, %r{Router OSPF priority})
      end

      it 'does not support 256 as a value' do
        expect { described_class.new(name: 'foo', priority: 256) }.to raise_error Puppet::Error, %r{Router OSPF priority}
      end

      it 'contains 50' do
        expect(described_class.new(name: 'foo', priority: 50)[:priority]).to eq(50)
      end

      it 'contains 51' do
        expect { described_class.new(name: 'foo', priority: '51') }.to raise_error Puppet::Error, %r{is not an Integer}
      end
    end

    describe 'retransmit_interval' do
      it 'supports 100 as a value' do
        expect { described_class.new(name: 'foo', retransmit_interval: 100) }.not_to raise_error
      end

      it 'does not support 0 as a value' do
        expect { described_class.new(name: 'foo', retransmit_interval: 0) }.to raise_error Puppet::Error, %r{OSPF retransmit interval}
      end

      it 'does not support 65536 as a value' do
        expect { described_class.new(name: 'foo', retransmit_interval: 65_536) }.to raise_error Puppet::Error, %r{OSPF retransmit interval}
      end

      it 'contains 50' do
        expect(described_class.new(name: 'foo', retransmit_interval: 50)[:retransmit_interval]).to eq(50)
      end

      it 'does not support \'51\'' do
        expect { described_class.new(name: 'foo', retransmit_interval: '51') }.to raise_error Puppet::Error, %r{is not an Integer}
      end
    end

    describe 'transmit_delay' do
      it 'supports 100 as a value' do
        expect { described_class.new(name: 'foo', transmit_delay: 100) }.not_to raise_error
      end

      it 'does not support 0 as a value' do
        expect { described_class.new(name: 'foo', transmit_delay: 0) }.to raise_error Puppet::Error, %r{OSPF transmit delay}
      end

      it 'does not support 65536 as a value' do
        expect { described_class.new(name: 'foo', transmit_delay: 65_536) }.to raise_error Puppet::Error, %r{OSPF transmit delay}
      end

      it 'contains 50' do
        expect(described_class.new(name: 'foo', transmit_delay: 50)[:transmit_delay]).to eq(50)
      end

      it 'does not support \'51\'' do
        expect { described_class.new(name: 'foo', transmit_delay: '51') }.to raise_error Puppet::Error, %r{is not an Integer}
      end
    end
  end

  describe 'when autorequiring' do
    it 'requires zebra and pimd services' do
      interface = described_class.new(name: 'eth0')
      catalog.add_resource zebra
      catalog.add_resource ospfd
      catalog.add_resource interface
      reqs = interface.autorequire

      expect(reqs.size).to eq(2)
      expect(reqs[0].source).to eq(zebra)
      expect(reqs[0].target).to eq(interface)
      expect(reqs[1].source).to eq(ospfd)
      expect(reqs[1].target).to eq(interface)
    end
  end
end
