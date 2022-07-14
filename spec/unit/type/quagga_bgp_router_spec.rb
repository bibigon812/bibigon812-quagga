require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_router) do
  let :providerclass do
    described_class.provide(:fake_quagga_provider) do
      attr_accessor :property_hash
      def create; end

      def destroy; end

      def exists?
        get(:ensure) == :present
      end

      def default_router_id
        '10.0.0.1'
      end
      mk_resource_methods
    end
  end

  before :each do
    Puppet::Type.type(:quagga_bgp_router).stubs(:defaultprovider).returns providerclass
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

    [:as_number, :import_check, :default_ipv4_unicast, :default_local_preference,
     :router_id, :keepalive, :holdtime].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'supports present as a value' do
        expect { described_class.new(name: 'bgp', ensure: :present) }.not_to raise_error
      end

      it 'supports absent as a value' do
        expect { described_class.new(name: 'bgp', ensure: :absent) }.not_to raise_error
      end

      it 'does not support other values' do
        expect { described_class.new(name: 'bgp', ensure: :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end
  end

  describe 'name' do
    it 'supports \'bgp\' as a value' do
      expect { described_class.new(name: 'bgp') }.not_to raise_error
    end

    it 'contains bgp' do
      expect(described_class.new(name: 'AS65000')[:name]).to eq('bgp')
    end
  end

  describe 'as_number' do
    it 'supports 65000 as a value' do
      expect { described_class.new(name: 'bgp', as_number: 65_000) }.not_to raise_error
    end

    it 'supports \'65000\' as a value' do
      expect { described_class.new(name: 'bgp', as_number: '65000') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support \'AS65000\' as a value' do
      expect { described_class.new(name: 'bgp', as_number: 'AS65000') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains 65000 as a value' do
      expect(described_class.new(name: 'bgp', as_number: 65_000)[:as_number]).to eq(65_000)
    end
  end

  [:import_check, :default_ipv4_unicast].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'supports \'true\' as a value' do
        expect { described_class.new(name: 'bgp', property => 'true') }.not_to raise_error
      end

      it 'supports :true as a value' do
        expect { described_class.new(name: 'bgp', property => :true) }.not_to raise_error
      end

      it 'supports true as a value' do
        expect { described_class.new(name: 'bgp', property => true) }.not_to raise_error
      end

      it 'supports \'false\' as a value' do
        expect { described_class.new(name: 'bgp', property => 'false') }.not_to raise_error
      end

      it 'supports :false as a value' do
        expect { described_class.new(name: 'bgp', property => :false) }.not_to raise_error
      end

      it 'supports false as a value' do
        expect { described_class.new(name: 'bgp', property => false) }.not_to raise_error
      end

      it 'does not support :enabled as a value' do
        expect { described_class.new(name: 'bgp', property => :enabled) }.to raise_error Puppet::Error
      end

      it 'does not support \'disabled\' as a value' do
        expect { described_class.new(name: 'bgp', property => 'disabled') }.to raise_error Puppet::Error
      end

      it 'contains \'true\' => true' do
        expect(described_class.new(name: 'bgp', property => 'true')[property]).to eq(:true)
      end

      it 'contains true => true' do
        expect(described_class.new(name: 'bgp', property => true)[property]).to eq(:true)
      end

      it 'contains true: true' do
        expect(described_class.new(name: 'bgp', property => :true)[property]).to eq(:true)
      end

      it 'contains \'false\' => :false' do
        expect(described_class.new(name: 'bgp', property => 'false')[property]).to eq(:false)
      end

      it 'contains false => :false' do
        expect(described_class.new(name: 'bgp', property => false)[property]).to eq(:false)
      end

      it 'contains :false => :false' do
        expect(described_class.new(name: 'bgp', property => :false)[property]).to eq(:false)
      end
    end
  end

  describe 'default_local_preference' do
    it 'supports \'100\' as a value' do
      expect { described_class.new(name: 'bgp', default_local_preference: '100') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'supports 200 as a value' do
      expect { described_class.new(name: 'bgp', default_local_preference: 200) }.not_to raise_error
    end

    it 'does not support 4294967296 as a value' do
      expect { described_class.new(name: 'bgp', default_local_preference: 4_294_967_296) }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support -100 as a value' do
      expect { described_class.new(name: 'bgp', default_local_preference: -100) }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains 500' do
      expect(described_class.new(name: 'bgp', default_local_preference: 500)[:default_local_preference]).to eq(500)
    end

    it 'contains 800' do
      expect(described_class.new(name: 'bgp', default_local_preference: 800)[:default_local_preference]).to eq(800)
    end
  end

  describe 'redistribute' do
    it 'supports \'ospf\' as a value' do
      expect { described_class.new(name: 'bgp', redistribute: 'ospf') }.not_to raise_error
    end

    it 'supports \'connected route-map QWER\' as a value' do
      expect { described_class.new(name: 'bgp', redistribute: 'connected route-map QWER') }.not_to raise_error
    end

    it 'does not support \'ospf\' as a value' do
      expect { described_class.new(name: 'bgp', redistribute: 'bgp') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support \'kernel metric 100 metric-type 3 route-map QWER\' as a value' do
      expect { described_class.new(name: 'bgp', redistribute: 'kernel metric 100 metric-type 3 route-map QWER') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains \'connected metric 100 metric-type 2 route-map QWER\'' do
      expect(described_class.new(name: 'bgp', redistribute: 'connected metric 100 route-map QWER')[:redistribute]).to eq(['connected metric 100 route-map QWER'])
    end
  end

  describe 'router_id' do
    it 'supports 192.168.1.1 as a value' do
      expect { described_class.new(name: 'bgp', router_id: '192.168.1.1') }.not_to raise_error
    end

    it 'does not support 256.1.1.1 as a value' do
      expect { described_class.new(name: 'bgp', router_id: '256.1.1.1') }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'does not support 1.-1.1.1 as a value' do
      expect { described_class.new(name: 'bgp', router_id: '1.-1.1.1') }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'contains 192.168.1.1' do
      expect(described_class.new(name: 'bgp', router_id: '192.168.1.1')[:router_id]).to eq('192.168.1.1')
    end

    it 'contains 1.1.1.1' do
      expect(described_class.new(name: 'bgp', router_id: '1.1.1.1')[:router_id]).to eq('1.1.1.1')
    end
  end

  describe 'keepalive/holdtime', type: :type do
    it 'supports 0/0 as a value' do
      expect { described_class.new(name: 'bgp', keepalive: 0, holdtime: 0) }.not_to raise_error
    end

    it 'supports 2/6 as a value' do
      expect { described_class.new(name: 'bgp', keepalive: 2, holdtime: 6) }.not_to raise_error
    end

    it 'does not support 3/8 as a value' do
      expect { described_class.new(name: 'bgp', keepalive: 3, holdtime: 8) }.to raise_error(RuntimeError, %r{keepalive must be 0})
    end

    it 'defaults to 3/9' do
      expect(described_class.new(name: 'bgp')).to(satisfy { |t| t[:keepalive] == 3 && t[:holdtime] == 9 })
    end

    it 'contains 0/0' do
      expect(described_class.new(name: 'bgp', keepalive: 0, holdtime: 0)).to(satisfy { |t| t[:keepalive] == 0 && t[:holdtime] == 0 })
    end

    it 'contains 2/6' do
      expect(described_class.new(name: 'bgp', keepalive: 2, holdtime: 6)).to(satisfy { |t| t[:keepalive] == 2 && t[:holdtime] == 6 })
    end
  end
end
