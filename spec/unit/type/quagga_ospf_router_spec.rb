require 'spec_helper'

describe Puppet::Type.type(:quagga_ospf_router) do
  let :providerclass do
    described_class.provide(:fake_quagga_provider) do
      attr_accessor :property_hash
      def create; end

      def destroy; end

      def exists?
        get(:ensure) == :present
      end

      def router_id
        '10.0.0.1'
      end
      mk_resource_methods
    end
  end

  before :each do
    Puppet::Type.type(:quagga_ospf_router).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_ospf)
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

    [
      :abr_type, :opaque, :rfc1583, :router_id, :log_adjacency_changes,
      :redistribute, :passive_interfaces, :distribute_list
    ].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'name' do
    it 'supports ospf as a value' do
      expect { described_class.new(name: 'ospf') }.not_to raise_error
    end

    it 'contains ospf' do
      expect(described_class.new(name: 'foo')[:name]).to eq('ospf')
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'supports present as a value' do
        expect { described_class.new(name: 'ospf', ensure: :present) }.not_to raise_error
      end

      it 'supports absent as a value' do
        expect { described_class.new(name: 'ospf', ensure: :absent) }.not_to raise_error
      end

      it 'does not support other values' do
        expect { described_class.new(name: 'ospf', ensure: :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end
  end

  describe 'abr_type' do
    it 'supports cisco as a value' do
      expect { described_class.new(name: 'ospf', abr_type: :cisco) }.not_to raise_error
    end

    it 'supports shortcut as a value' do
      expect { described_class.new(name: 'ospf', abr_type: :shortcut) }.not_to raise_error
    end

    it 'does not support juniper as a value' do
      expect { described_class.new(name: 'ospf', abr_type: :juniper) }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'contains ibm' do
      expect(described_class.new(name: 'ospf', abr_type: :ibm)[:abr_type]).to eq(:ibm)
    end

    it 'contains standard' do
      expect(described_class.new(name: 'ospf', abr_type: :standard)[:abr_type]).to eq(:standard)
    end
  end

  [:opaque, :rfc1583].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'supports true as a value' do
        expect { described_class.new(name: 'ospf', property => true) }.not_to raise_error
      end

      it 'supports false as a value' do
        expect { described_class.new(name: 'ospf', property => false) }.not_to raise_error
      end

      it 'contains :true' do
        expect(described_class.new(name: 'ospf', property => true)[property]).to eq(:true)
      end

      it 'contains :false' do
        expect(described_class.new(name: 'ospf', property => false)[property]).to eq(:false)
      end

      it 'does not support foo as a value' do
        expect { described_class.new(name: 'ospf', property => :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end
  end

  describe 'redistribute' do
    it 'supports \'bgp\' as a value' do
      expect { described_class.new(name: 'ospf', redistribute: 'bgp') }.not_to raise_error
    end

    it 'supports \'connected route-map QWER\' as a value' do
      expect { described_class.new(name: 'ospf', redistribute: 'connected route-map QWER') }.not_to raise_error
    end

    it 'does not support \'ospf\' as a value' do
      expect { described_class.new(name: 'ospf', redistribute: 'ospf') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support \'kernel metric 100 metric-type 3 route-map QWER\' as a value' do
      expect { described_class.new(name: 'ospf', redistribute: 'kernel metric 100 metric-type 3 route-map QWER') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains \'connected metric 100 metric-type 2 route-map QWER\'' do
      expect(described_class.new(name: 'ospf', redistribute: 'connected metric 100 metric-type 2 route-map QWER')[:redistribute]).to eq(['connected metric 100 route-map QWER'])
    end
  end

  describe 'router_id' do
    it 'supports \'1.1.1.1\' as a value' do
      expect { described_class.new(name: 'ospf', router_id: '1.1.1.1') }.not_to raise_error
    end

    it 'supports \'0.0.0.0\' as a value' do
      expect { described_class.new(name: 'ospf', router_id: '0.0.0.0') }.not_to raise_error
    end

    it 'supports \'255.255.255.255\' as a value' do
      expect { described_class.new(name: 'ospf', router_id: '255.255.255.255') }.not_to raise_error
    end

    it 'does not support \'1.1000.1.1\' as a value' do
      expect { described_class.new(name: 'ospf', router_id: '1.1000.1.1') }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'does not support \'1.100.256.1\' as a value' do
      expect { described_class.new(name: 'ospf', router_id: '1.100.256.1') }.to raise_error(Puppet::Error, %r{Invalid value})
    end

    it 'contains \'1.1.1.1\'' do
      expect(described_class.new(name: 'ospf', router_id: '1.1.1.1')[:router_id]).to eq('1.1.1.1')
    end

    it 'the default value should insync with :absent' do
      expect(described_class.new(name: :ospf).property(:router_id).insync?(:absent)).to eq(true)
    end

    it 'the default value does not insync with \'10.0.0.1\'' do
      expect(described_class.new(name: :ospf).property(:router_id).insync?('10.0.0.1')).to eq(false)
    end

    it '\'10.0.0.1\' does not insync with :absent' do
      expect(described_class.new(name: :ospf, router_id: '10.0.0.1').property(:router_id).insync?(:absent)).to eq(false)
    end
  end

  describe 'log_adjacency_changes' do
    it 'supports true as a value' do
      expect { described_class.new(name: 'ospf', log_adjacency_changes: true) }.not_to raise_error
    end

    it 'supports false as a value' do
      expect { described_class.new(name: 'ospf', log_adjacency_changes: false) }.not_to raise_error
    end

    it 'supports detail as a value' do
      expect { described_class.new(name: 'ospf', log_adjacency_changes: :detail) }.not_to raise_error
    end

    it 'contains :true' do
      expect(described_class.new(name: 'ospf', log_adjacency_changes: true)[:log_adjacency_changes]).to eq(:true)
    end

    it 'contains :false' do
      expect(described_class.new(name: 'ospf', log_adjacency_changes: false)[:log_adjacency_changes]).to eq(:false)
    end

    it 'contains :detail' do
      expect(described_class.new(name: 'ospf', log_adjacency_changes: :detail)[:log_adjacency_changes]).to eq(:detail)
    end

    it 'does not support foo as a value' do
      expect { described_class.new(name: 'ospf', log_adjacency_changes: :foo) }.to raise_error Puppet::Error, %r{Invalid value}
    end
  end

  describe 'default_originate' do
    it 'supports \'always metric 100 metric-type 2 route-map QWER\'' do
      expect { described_class.new(name: 'ospf', default_originate: 'always metric 100 metric-type 2 route-map QWER') }.not_to raise_error
    end

    it 'supports \'always\'' do
      expect { described_class.new(name: 'ospf', default_originate: 'always') }.not_to raise_error
    end

    it 'supports :true' do
      expect { described_class.new(name: 'ospf', default_originate: :true) }.not_to raise_error
    end

    it 'supports \'true\'' do
      expect { described_class.new(name: 'ospf', default_originate: 'true') }.not_to raise_error
    end

    it 'does not support \'always metric 100 metric-type 3 route-map QWER\'' do
      expect { described_class.new(name: 'ospf', default_originate: 'always metric 100 metric-type 3 route-map QWER') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains \'always metric 100 metric-type 2 route-map QWER\'' do
      expect(described_class.new(name: 'ospf', default_originate: 'always metric 100 metric-type 2 route-map QWER')[:default_originate]).to eq('always metric 100 route-map QWER')
    end

    it 'contains \'always metric 100 metric-type 1 route-map QWER\'' do
      expect(described_class.new(name: 'ospf', default_originate: 'always metric 100 metric-type 1 route-map QWER')[:default_originate]).to eq('always metric 100 metric-type 1 route-map QWER')
    end

    it 'contains \'false\'' do
      expect(described_class.new(name: 'ospf')[:default_originate]).to eq(:false)
    end
  end

  describe 'passive_interfaces' do
    it 'supports default as a value' do
      expect { described_class.new(name: 'ospf', passive_interfaces: 'default') }.not_to raise_error
    end
  end

  describe 'distribute_list' do
    it 'supports \'LIST out bgp\' as a value' do
      expect { described_class.new(name: 'ospf', distribute_list: 'LIST out bgp') }.not_to raise_error
    end

    it 'supports \'LIST out kernel\' as a value' do
      expect { described_class.new(name: 'ospf', distribute_list: 'LIST out kernel') }.not_to raise_error
    end

    it 'does not support \'LIST out ospf\' as a value' do
      expect { described_class.new(name: 'ospf', distribute_list: 'LIST out ospf') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support \'LIST in kernel\' as a value' do
      expect { described_class.new(name: 'ospf', distribute_list: 'LIST in kernel') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains \'LIST out connected\'' do
      expect(described_class.new(name: 'ospf', distribute_list: 'LIST out connected')[:distribute_list]).to eq(['LIST out connected'])
    end
  end
end
