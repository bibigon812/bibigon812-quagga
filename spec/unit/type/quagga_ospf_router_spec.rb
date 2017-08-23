require 'spec_helper'

describe Puppet::Type.type(:quagga_ospf_router) do
  let :providerclass  do
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

  it 'should have :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [
      :abr_type, :opaque, :rfc1583, :router_id, :log_adjacency_changes,
      :redistribute, :passive_interfaces, :distribute_list,
    ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'name' do
    it 'should support ospf as a value' do
      expect { described_class.new(:name => 'ospf') }.to_not raise_error
    end

    it 'should contain ospf' do
      expect(described_class.new(:name => 'foo')[:name]).to eq('ospf')
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'ospf', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'ospf', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'ospf', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'abr_type' do
    it 'should support cisco as a value' do
      expect { described_class.new(:name => 'ospf', :abr_type => :cisco) }.to_not raise_error
    end

    it 'should support shortcut as a value' do
      expect { described_class.new(:name => 'ospf', :abr_type => :shortcut) }.to_not raise_error
    end

    it 'should not support juniper as a value' do
      expect { described_class.new(:name => 'ospf', :abr_type => :juniper) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain ibm' do
      expect(described_class.new(:name => 'ospf', :abr_type => :ibm)[:abr_type]).to eq(:ibm)
    end

    it 'should contain standard' do
      expect(described_class.new(:name => 'ospf', :abr_type => :standard)[:abr_type]).to eq(:standard)
    end
  end

  [:opaque, :rfc1583].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'should support true as a value' do
        expect { described_class.new(:name => 'ospf', property => true) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(:name => 'ospf', property => false) }.to_not raise_error
      end

      it 'should contain :true' do
        expect(described_class.new(:name => 'ospf', property => true)[property]).to eq(:true)
      end

      it 'should contain :false' do
        expect(described_class.new(:name => 'ospf', property => false)[property]).to eq(:false)
      end

      it 'should not support foo as a value' do
        expect { described_class.new(:name => 'ospf', property => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'redistribute' do
    it 'should support \'bgp\' as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => 'bgp') }.to_not raise_error
    end

    it 'should support \'connected route-map QWER\' as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => 'connected route-map QWER') }.to_not raise_error
    end

    it 'should not support \'ospf\' as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => 'ospf') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support \'kernel metric 100 metric-type 3 route-map QWER\' as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => 'kernel metric 100 metric-type 3 route-map QWER') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain \'connected metric 100 metric-type 2 route-map QWER\'' do
      expect(described_class.new(:name => 'ospf', :redistribute => 'connected metric 100 metric-type 2 route-map QWER')[:redistribute]).to eq(['connected metric 100 route-map QWER'])
    end
  end

  describe 'router_id' do
    it 'should support \'1.1.1.1\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '1.1.1.1') }.to_not raise_error
    end

    it 'should support \'0.0.0.0\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '0.0.0.0') }.to_not raise_error
    end

    it 'should support \'255.255.255.255\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '255.255.255.255') }.to_not raise_error
    end

    it 'should not support \'1.1000.1.1\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '1.1000.1.1') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support \'1.100.256.1\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '1.100.256.1') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain \'1.1.1.1\'' do
      expect(described_class.new(:name => 'ospf', :router_id => '1.1.1.1')[:router_id]).to eq('1.1.1.1')
    end

    it 'the default value should insync with :absent' do
      expect(described_class.new(name: :ospf).property(:router_id).insync?(:absent)).to eq(true)
    end

    it 'the default value should not insync with \'10.0.0.1\'' do
      expect(described_class.new(name: :ospf).property(:router_id).insync?('10.0.0.1')).to eq(false)
    end

    it '\'10.0.0.1\' should not insync with :absent' do
      expect(described_class.new(name: :ospf, router_id: '10.0.0.1').property(:router_id).insync?(:absent)).to eq(false)
    end
  end

  describe 'log_adjacency_changes' do
    it 'should support true as a value' do
      expect { described_class.new(:name => 'ospf', :log_adjacency_changes => true) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => 'ospf', :log_adjacency_changes => false) }.to_not raise_error
    end

    it 'should support detail as a value' do
      expect { described_class.new(:name => 'ospf', :log_adjacency_changes => :detail) }.to_not raise_error
    end

    it 'should contain :true' do
      expect(described_class.new(:name => 'ospf', :log_adjacency_changes => true)[:log_adjacency_changes]).to eq(:true)
    end

    it 'should contain :false' do
      expect(described_class.new(:name => 'ospf', :log_adjacency_changes => false)[:log_adjacency_changes]).to eq(:false)
    end

    it 'should contain :detail' do
      expect(described_class.new(:name => 'ospf', :log_adjacency_changes => :detail)[:log_adjacency_changes]).to eq(:detail)
    end

    it 'should not support foo as a value' do
      expect { described_class.new(:name => 'ospf', :log_adjacency_changes => :foo) }.to raise_error Puppet::Error, /Invalid value/
    end
  end

  describe 'default_originate' do
    it 'should support \'always metric 100 metric-type 2 route-map QWER\'' do
      expect{described_class.new(:name => 'ospf', :default_originate => 'always metric 100 metric-type 2 route-map QWER')}.to_not raise_error
    end

    it 'should support \'always\'' do
      expect{described_class.new(:name => 'ospf', :default_originate => 'always')}.to_not raise_error
    end

    it 'should support :true' do
      expect{described_class.new(:name => 'ospf', :default_originate => :true)}.to_not raise_error
    end

    it 'should support \'true\'' do
      expect{described_class.new(:name => 'ospf', :default_originate => 'true')}.to_not raise_error
    end

    it 'should not support \'always metric 100 metric-type 3 route-map QWER\'' do
      expect{described_class.new(:name => 'ospf', :default_originate => 'always metric 100 metric-type 3 route-map QWER')}.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain \'always metric 100 metric-type 2 route-map QWER\'' do
      expect(described_class.new(:name => 'ospf', :default_originate => 'always metric 100 metric-type 2 route-map QWER')[:default_originate]).to eq('always metric 100 route-map QWER')
    end

    it 'should contain \'always metric 100 metric-type 1 route-map QWER\'' do
      expect(described_class.new(:name => 'ospf', :default_originate => 'always metric 100 metric-type 1 route-map QWER')[:default_originate]).to eq('always metric 100 metric-type 1 route-map QWER')
    end

    it 'should contain \'false\'' do
      expect(described_class.new(:name => 'ospf')[:default_originate]).to eq(:false)
    end
  end

  describe 'passive_interfaces' do
    it 'should support default as a value' do
      expect{described_class.new(:name => 'ospf', :passive_interfaces => 'default')}.to_not raise_error
    end
  end

  describe 'distribute_list' do
    it 'should support \'LIST out bgp\' as a value' do
      expect { described_class.new(:name => 'ospf', :distribute_list => 'LIST out bgp') }.to_not raise_error
    end

    it 'should support \'LIST out kernel\' as a value' do
      expect { described_class.new(:name => 'ospf', :distribute_list => 'LIST out kernel') }.to_not raise_error
    end

    it 'should not support \'LIST out ospf\' as a value' do
      expect { described_class.new(:name => 'ospf', :distribute_list => 'LIST out ospf') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support \'LIST in kernel\' as a value' do
      expect { described_class.new(:name => 'ospf', :distribute_list => 'LIST in kernel') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain \'LIST out connected\'' do
      expect(described_class.new(:name => 'ospf', :distribute_list => 'LIST out connected')[:distribute_list]).to eq(['LIST out connected'])
    end
  end
end
