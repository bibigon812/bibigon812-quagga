require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_peer) do
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

  before :each do
    Puppet::Type.type(:quagga_bgp_peer).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_bgp_peer)
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

    [:local_as, :passive, :peer_group, :remote_as, :shutdown].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'supports present as a value' do
        expect { described_class.new(name: '192.168.1.1', ensure: :present) }.not_to raise_error
      end

      it 'supports absent as a value' do
        expect { described_class.new(name: '192.168.1.1', ensure: :absent) }.not_to raise_error
      end

      it 'does not support foo values' do
        expect { described_class.new(name: '192.168.1.1', ensure: :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end
  end

  describe 'name' do
    it 'supports 192.168.1.1 as a value' do
      expect { described_class.new(name: '192.168.1.1') }.not_to raise_error
    end

    it 'supports 10.1.1.1 as a value' do
      expect { described_class.new(name: '10.1.1.1') }.not_to raise_error
    end

    it 'supports 10.1.1.0 as a value' do
      expect { described_class.new(name: '10.1.1.0') }.not_to raise_error
    end

    it 'supports 2aff::1 as a value' do
      expect { described_class.new(name: '2aff::1') }.not_to raise_error
    end

    it 'does not support 10.256.0.0 as a value' do
      expect { described_class.new(name: '100:10.256.0.0') }.to raise_error(Puppet::Error, %r{Invalid value})
    end
  end

  [:passive].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'supports \'true\' as a value' do
        expect { described_class.new(name: '192.168.1.1', property => 'true') }.not_to raise_error
      end

      it 'supports :true as a value' do
        expect { described_class.new(name: '192.168.1.1', property => :true) }.not_to raise_error
      end

      it 'supports true as a value' do
        expect { described_class.new(name: '192.168.1.1', property => true) }.not_to raise_error
      end

      it 'supports \'false\' as a value' do
        expect { described_class.new(name: '192.168.1.1', property => 'false') }.not_to raise_error
      end

      it 'supports :false as a value' do
        expect { described_class.new(name: '192.168.1.1', property => :false) }.not_to raise_error
      end

      it 'supports false as a value' do
        expect { described_class.new(name: '192.168.1.1', property => false) }.not_to raise_error
      end

      it 'does not support :enabled as a value' do
        expect { described_class.new(name: '192.168.1.1', property => :enabled) }.to raise_error(Puppet::Error, %r{Invalid value})
      end

      it 'does not support \'disabled\' as a value' do
        expect { described_class.new(name: '192.168.1.1', property => 'disabled') }.to raise_error(Puppet::Error, %r{Invalid value})
      end

      it 'contains :true when passed string "true"' do
        expect(described_class.new(name: '192.168.1.1', property => 'true')[property]).to eq(:true)
      end

      it 'contains :true when passed value true' do
        expect(described_class.new(name: '192.168.1.1', property => true)[property]).to eq(:true)
      end

      it 'contains :false when passed string "false"' do
        expect(described_class.new(name: '192.168.1.1', property => 'false')[property]).to eq(:false)
      end

      it 'contains :false when passed value false' do
        expect(described_class.new(name: '192.168.1.1', property => false)[property]).to eq(:false)
      end
    end
  end

  describe 'peer_group' do
    it 'supports \'true\' as a value' do
      expect { described_class.new(name: '192.168.1.1', peer_group: 'true') }.not_to raise_error
    end

    it 'supports :true as a value' do
      expect { described_class.new(name: '192.168.1.1', peer_group: :true) }.not_to raise_error
    end

    it 'supports true as a value' do
      expect { described_class.new(name: '192.168.1.1', peer_group: true) }.not_to raise_error
    end

    it 'supports \'false\' as a value' do
      expect { described_class.new(name: '192.168.1.1', peer_group: 'false') }.not_to raise_error
    end

    it 'supports :false as a value' do
      expect { described_class.new(name: '192.168.1.1', peer_group: :false) }.not_to raise_error
    end

    it 'supports false as a value' do
      expect { described_class.new(name: '192.168.1.1', peer_group: false) }.not_to raise_error
    end

    it 'supports peer_group as a value' do
      expect { described_class.new(name: '192.168.1.1', peer_group: 'peer_group') }.not_to raise_error
    end

    it 'supports peer_group_1 as a value' do
      expect { described_class.new(name: '192.168.1.1', peer_group: :peer_group_1) }.not_to raise_error
    end

    it 'does not support 9-allow as a value' do
      expect { described_class.new(name: '192.168.1.1', peer_group: '9-allow') }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'contains true when passed string "true"' do
      expect(described_class.new(name: '192.168.1.1', peer_group: 'true')[:peer_group]).to eq(:true)
    end

    it 'contains true when passed value true' do
      expect(described_class.new(name: '192.168.1.1', peer_group: true)[:peer_group]).to eq(:true)
    end

    it 'contains false' do
      expect(described_class.new(name: '192.168.1.1', peer_group: 'false')[:peer_group]).to eq(:false)
    end

    it 'contains :false' do
      expect(described_class.new(name: '192.168.1.1', peer_group: false)[:peer_group]).to eq(:false)
    end

    it 'contains peer_group' do
      expect(described_class.new(name: '192.168.1.1', peer_group: 'peer_group')[:peer_group]).to eq('peer_group')
    end

    it 'contains peer_group_1' do
      expect(described_class.new(name: '192.168.1.1', peer_group: 'peer_group_1')[:peer_group]).to eq('peer_group_1')
    end
  end

  [:local_as, :remote_as].each do |property|
    describe property.to_s do
      it 'does not supports quoted numeric strings' do
        expect { described_class.new(name: '192.168.1.1', property => '100') }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'supports 100 as a value' do
        expect { described_class.new(name: '192.168.1.1', property => 100) }.not_to raise_error
      end

      it 'does not support 0 as a value' do
        expect { described_class.new(name: '192.168.1.1', property => 0) }.to raise_error(Puppet::Error, %r{Invalid value})
      end

      it 'does not support AS100 as a value' do
        expect { described_class.new(name: '192.168.1.1', property => 'AS100') }.to raise_error(Puppet::Error, %r{Invalid value})
      end

      it 'contains 100' do
        expect(described_class.new(name: '192.168.1.1', property => 100)[property]).to eq(100)
      end
    end
  end

  describe 'update_source' do
    it 'supports eth1 as a value' do
      expect { described_class.new(name: '192.168.1.1', update_source: 'eth1') }.not_to raise_error
    end

    it 'supports 10.0.0.1 as a value' do
      expect { described_class.new(name: '192.168.1.1', update_source: '10.0.0.1') }.not_to raise_error
    end

    it 'does not support 0bond0 as a value' do
      expect { described_class.new(name: '192.168.1.1', update_source: '0bond0') }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'does not support 10.256.0.1 as a value' do
      expect { described_class.new(name: '192.168.1.1', update_source: '10.256.0.1') }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'contains eth0' do
      expect(described_class.new(name: '192.168.1.1', update_source: 'eth0')[:update_source]).to eq('eth0')
    end

    it 'contains 10.0.0.2' do
      expect(described_class.new(name: '192.168.1.1', update_source: '10.0.0.2')[:update_source]).to eq('10.0.0.2')
    end
  end

  describe 'ebgp_multihop' do
    it 'supports 2 as a value' do
      expect { described_class.new(name: '192.168.1.1', ebgp_multihop: 2) }.not_to raise_error
    end

    it 'contains 2 when set' do
      expect(described_class.new(name: '192.168.1.1', ebgp_multihop: 2)[:ebgp_multihop]).to eq(2)
    end

    [
      '0bond0',
      '10.256.0.1',
      -1,
      256,
    ].each do |invalid_value|
      it "does not support #{invalid_value} as a value" do
        expect { described_class.new(name: '192.168.1.1', ebgp_multihop: invalid_value) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end
  end

  describe 'password' do
    it 'supports string as a value' do
      expect { described_class.new(name: '192.168.1.1', password: 'QWRF$345!#@$') }.not_to raise_error
    end

    it 'contains QWRF$345!#@$' do
      expect(described_class.new(name: '192.168.1.1', password: 'QWRF$345!#@$')[:password]).to eq('QWRF$345!#@$')
    end
  end
end
