require 'spec_helper'

describe Puppet::Type.type(:quagga_ospf_interface) do
  let :providerclass  do
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

  let(:zebra) { Puppet::Type.type(:service).new(:name => 'zebra') }
  let(:ospfd) { Puppet::Type.type(:service).new(:name => 'ospfd') }
  let(:catalog) { Puppet::Resource::Catalog.new }

  before :each do
    described_class.stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_interface)
  end

  it 'should have :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [ :auth, :message_digest_key, :cost, :dead_interval,
      :hello_interval, :mtu_ignore, :network,
      :priority, :retransmit_interval, :transmit_delay,
    ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'auth' do
      it 'should support :absent as a value' do
        expect { described_class.new(:name => 'foo', :auth => :absent) }.to_not raise_error
      end

      it 'should support message-digest as a value' do
        expect { described_class.new(:name => 'foo', :auth => "message-digest") }.to_not raise_error
      end

      it 'should contain :message-digest' do
        expect(described_class.new(name: 'foo', :auth => 'message-digest')[:auth]).to eq(:"message-digest")
      end

      it 'should not support foo as a value' do
        expect { described_class.new(:name => 'foo', :auth => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'message_digest_key' do
      it 'should support :absent as a value' do
        expect { described_class.new(:name => 'foo', :message_digest_key => :absent) }.to_not raise_error
      end

      it 'should support "1 md5 hello123" as a value' do
        expect { described_class.new(:name => 'foo', :message_digest_key => "1 md5 hello123") }.to_not raise_error
      end

      it 'should contain "1 md5 hello123"' do
        expect(described_class.new(name: 'foo', :message_digest_key => '1 md5 hello123')[:message_digest_key]).to eq('1 md5 hello123')
      end

      it 'should not support foo as a value' do
        expect { described_class.new(:name => 'foo', :message_digest_key => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'cost' do
      it 'should support :absent as a value' do
        expect { described_class.new(:name => 'foo', :cost => :absent) }.to_not raise_error
      end

      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :cost => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :cost => 0) }.to raise_error(Puppet::Error, /OSPF cost/)
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :cost => 65536) }.to raise_error(Puppet::Error, /OSPF cost/)
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :cost => 50)[:cost]).to eq(50)
      end

      it 'should contain 51' do
        expect { described_class.new(:name => 'foo', :cost => '51') }.to raise_error Puppet::Error, /OSPF cost/
      end
    end

    describe 'dead_interval' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :dead_interval => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :dead_interval => 0) }.to raise_error Puppet::Error, /OSPF dead interval/
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :dead_interval => 65536) }.to raise_error Puppet::Error, /OSPF dead interval/
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :dead_interval => 50)[:dead_interval]).to eq(50)
      end

      it 'should contain 51' do
        expect { described_class.new(:name => 'foo', :dead_interval => '51') }.to raise_error Puppet::Error, /OSPF dead interval/
      end
    end

    describe 'hello_interval' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :hello_interval => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :hello_interval => 0) }.to raise_error Puppet::Error, /OSPF hello packets interval/
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :hello_interval => 65536) }.to raise_error Puppet::Error, /OSPF hello packets interval/
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :hello_interval => 50)[:hello_interval]).to eq(50)
      end

      it 'should contain 51' do
        expect { described_class.new(:name => 'foo', :hello_interval => '51') }.to raise_error Puppet::Error, /OSPF hello packets interval/
      end
    end

    [:mtu_ignore].each do |property|
      describe "#{property}" do
        it 'should support true as a value' do
          expect { described_class.new(:name => 'foo', property => true) }.to_not raise_error
        end

        it 'should support :true as a value' do
          expect { described_class.new(:name => 'foo', property => :true) }.to_not raise_error
        end

        it 'should support :true as a value' do
          expect { described_class.new(:name => 'foo', property => 'true') }.to_not raise_error
        end

        it 'should support false as a value' do
          expect { described_class.new(:name => 'foo', property => false) }.to_not raise_error
        end

        it 'should support :false as a value' do
          expect { described_class.new(:name => 'foo', property => :false) }.to_not raise_error
        end

        it 'should support :false as a value' do
          expect { described_class.new(:name => 'foo', property => 'false') }.to_not raise_error
        end

        it 'should not support foo as a value' do
          expect { described_class.new(:name => 'foo', property => :disabled) }.to raise_error Puppet::Error, /Invalid value/
        end

        it 'should contain enabled' do
          expect(described_class.new(:name => 'foo', property => 'true')[property]).to eq(:true)
        end

        it 'should contain enabled' do
          expect(described_class.new(:name => 'foo', property => :true)[property]).to eq(:true)
        end

        it 'should contain enabled' do
          expect(described_class.new(:name => 'foo', property => true)[property]).to eq(:true)
        end

        it 'should contain disabled' do
          expect(described_class.new(:name => 'foo', property => 'false')[property]).to eq(:false)
        end

        it 'should contain disabled' do
          expect(described_class.new(:name => 'foo', property => :false)[property]).to eq(:false)
        end

        it 'should contain disabled' do
          expect(described_class.new(:name => 'foo', property => false)[property]).to eq(:false)
        end
      end
    end


    describe 'network' do
      it 'should support :broadcast as value' do
        expect { described_class.new(:name => 'foo', :network => 'broadcast') }.to_not raise_error
      end

      it 'should support non-broadcast as value' do
        expect { described_class.new(:name => 'foo', :network => 'non-broadcast') }.to_not raise_error
      end

      it 'should support point-to-multipoint as value' do
        expect { described_class.new(:name => 'foo', :network => 'point-to-multipoint') }.to_not raise_error
      end

      it 'should support point-to-point as value' do
        expect { described_class.new(:name => 'foo', :network => 'point-to-point') }.to_not raise_error
      end

      it 'should support :absent as value' do
        expect { described_class.new(:name => 'foo', :network => :absent) }.to_not raise_error
      end

      it 'should contain point-to-point' do
        expect(described_class.new(:name => 'foo', :network => 'point-to-point')[:network]).to eq(:"point-to-point")
      end
    end

    describe 'priority' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :priority => 100) }.to_not raise_error
      end

      it 'should not support -1 as a value' do
        expect { described_class.new(:name => 'foo', :priority => -1) }.to raise_error(Puppet::Error, /Router OSPF priority/)
      end

      it 'should not support 256 as a value' do
        expect { described_class.new(:name => 'foo', :priority => 256) }.to raise_error Puppet::Error, /Router OSPF priority/
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :priority => 50)[:priority]).to eq(50)
      end

      it 'should contain 51' do
        expect { described_class.new(:name => 'foo', :priority => '51') }.to raise_error Puppet::Error, /is not an Integer/
      end
    end

    describe 'retransmit_interval' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :retransmit_interval => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :retransmit_interval => 0) }.to raise_error Puppet::Error, /OSPF retransmit interval/
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :retransmit_interval => 65536) }.to raise_error Puppet::Error, /OSPF retransmit interval/
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :retransmit_interval => 50)[:retransmit_interval]).to eq(50)
      end

      it 'should not support \'51\'' do
        expect { described_class.new(:name => 'foo', :retransmit_interval => '51') }.to raise_error Puppet::Error, /is not an Integer/
      end
    end

    describe 'transmit_delay' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :transmit_delay => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :transmit_delay => 0) }.to raise_error Puppet::Error, /OSPF transmit delay/
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :transmit_delay => 65536) }.to raise_error Puppet::Error, /OSPF transmit delay/
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :transmit_delay => 50)[:transmit_delay]).to eq(50)
      end

      it 'should not support \'51\'' do
        expect { described_class.new(:name => 'foo', :transmit_delay => '51') }.to raise_error Puppet::Error, /is not an Integer/
      end
    end
  end

  describe 'when autorequiring' do
    it 'should require zebra and pimd services' do
      interface = described_class.new(:name => 'eth0')
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
