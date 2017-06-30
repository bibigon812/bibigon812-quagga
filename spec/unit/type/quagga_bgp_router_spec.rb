require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_router) do
  let :providerclass  do
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

  it 'should have :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:import_check, :default_ipv4_unicast, :default_local_preference,
     :router_id,].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'bgp', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'bgp', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'bgp', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'name' do
    it 'should support \'bgp\' as a value' do
      expect { described_class.new(:name => 'bgp') }.to_not raise_error
    end

    it 'should not support AS197888 as a value' do
      expect { described_class.new(:name => 'AS197888') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  [:import_check, :default_ipv4_unicast].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'should support \'true\' as a value' do
        expect { described_class.new(:name => 'bgp', property => 'true') }.to_not raise_error
      end

      it 'should support :true as a value' do
        expect { described_class.new(:name => 'bgp', property => :true) }.to_not raise_error
      end

      it 'should support true as a value' do
        expect { described_class.new(:name => 'bgp', property => true) }.to_not raise_error
      end

      it 'should support \'yes\' as a value' do
        expect { described_class.new(:name => 'bgp', property => 'yes') }.to_not raise_error
      end

      it 'should support :yes as a value' do
        expect { described_class.new(:name => 'bgp', property => :yes) }.to_not raise_error
      end

      it 'should support \'false\' as a value' do
        expect { described_class.new(:name => 'bgp', property => 'false') }.to_not raise_error
      end

      it 'should support :false as a value' do
        expect { described_class.new(:name => 'bgp', property => :false) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(:name => 'bgp', property => false) }.to_not raise_error
      end

      it 'should support \'no\' as a value' do
        expect { described_class.new(:name => 'bgp', property => 'no') }.to_not raise_error
      end

      it 'should support :no as a value' do
        expect { described_class.new(:name => 'bgp', property => :no) }.to_not raise_error
      end

      it 'should not support :enabled as a value' do
        expect { described_class.new(:name => 'bgp', property => :enabled) }.to raise_error Puppet::Error
      end

      it 'should not support \'disabled\' as a value' do
        expect { described_class.new(:name => 'bgp', property => 'disabled') }.to raise_error Puppet::Error
      end

      it 'should contain \'true\' => true' do
        expect(described_class.new(:name => 'bgp', property => 'true')[property]).to eq(true)
      end

      it 'should contain true => true' do
        expect(described_class.new(:name => 'bgp', property => true)[property]).to eq(true)
      end

      it 'should contain :true => true' do
        expect(described_class.new(:name => 'bgp', property => true)[property]).to eq(true)
      end

      it 'should contain \'yes\' => true' do
        expect(described_class.new(:name => 'bgp', property => 'yes')[property]).to eq(true)
      end

      it 'should contain :yes => true' do
        expect(described_class.new(:name => 'bgp', property => :yes)[property]).to eq(true)
      end

      it 'should contain \'false\' => false' do
        expect(described_class.new(:name => 'bgp', property => 'false')[property]).to eq(false)
      end

      it 'should contain false => false' do
        expect(described_class.new(:name => 'bgp', property => false)[property]).to eq(false)
      end
    end
  end

  describe 'default_local_preference' do
    it 'should support \'100\' as a value' do
      expect { described_class.new(:name => 'bgp', :default_local_preference => '100') }.to_not raise_error
    end

    it 'should support 200 as a value' do
      expect { described_class.new(:name => 'bgp', :default_local_preference => 200) }.to_not raise_error
    end

    it 'should not support \'0\' as a value' do
      expect { described_class.new(:name => 'bgp', :default_local_preference => '0') }.to_not raise_error
    end

    it 'should not support 4294967296 as a value' do
      expect { described_class.new(:name => 'bgp', :default_local_preference => 4294967296) }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support -100 as a value' do
      expect { described_class.new(:name => 'bgp', :default_local_preference => -100) }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain 500' do
      expect(described_class.new(:name => 'bgp', :default_local_preference => '500')[:default_local_preference]).to eq(500)
    end

    it 'should contain 800' do
      expect(described_class.new(:name => 'bgp', :default_local_preference => 800)[:default_local_preference]).to eq(800)
    end
  end

  describe 'redistribute' do
    it 'should support \'ospf\' as a value' do
      expect { described_class.new(:name => 'bgp', :redistribute => 'ospf') }.to_not raise_error
    end

    it 'should support \'connected route-map QWER\' as a value' do
      expect { described_class.new(:name => 'bgp', :redistribute => 'connected route-map QWER') }.to_not raise_error
    end

    it 'should not support \'ospf\' as a value' do
      expect { described_class.new(:name => 'bgp', :redistribute => 'bgp') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support \'kernel metric 100 metric-type 3 route-map QWER\' as a value' do
      expect { described_class.new(:name => 'bgp', :redistribute => 'kernel metric 100 metric-type 3 route-map QWER') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain \'connected metric 100 metric-type 2 route-map QWER\'' do
      expect(described_class.new(:name => 'bgp', :redistribute => 'connected metric 100 route-map QWER')[:redistribute]).to eq(['connected metric 100 route-map QWER'])
    end
  end

  describe 'router_id' do
    it 'should support 192.168.1.1 as a value' do
      expect { described_class.new(:name => 'bgp', :router_id => '192.168.1.1') }.to_not raise_error
    end

    it 'should not support 256.1.1.1 as a value' do
      expect { described_class.new(:name => 'bgp', :router_id => '256.1.1.1') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 1.-1.1.1 as a value' do
      expect { described_class.new(:name => 'bgp', :router_id => '1.-1.1.1') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain 192.168.1.1' do
      expect(described_class.new(:name => 'bgp', :router_id => '192.168.1.1')[:router_id]).to eq('192.168.1.1')
    end

    it 'should contain 1.1.1.1' do
      expect(described_class.new(:name => 'bgp', :router_id => '1.1.1.1')[:router_id]).to eq('1.1.1.1')
    end
  end
end