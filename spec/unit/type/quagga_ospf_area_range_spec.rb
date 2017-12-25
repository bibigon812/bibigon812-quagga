require 'spec_helper'

describe Puppet::Type.type(:quagga_ospf_area_range) do
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

  let(:ospf_area) { Puppet::Type.type(:quagga_ospf_area).new(name: '0.0.0.0') }
  let(:catalog) { Puppet::Resource::Catalog.new }

  before :each do
    Puppet::Type.type(:quagga_ospf_area_range).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_ospf_area_range)
  end

  it 'should have :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :advertise, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:cost, :substitute].each do |property|
      it "should have the property '#{property}'" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end


  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(title: '0.0.0.0 192.168.0.0/24', ensure: :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(title: '0.0.0.0 192.168.0.0/24', ensure: :present) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(title: '0.0.0.0 192.168.0.0/24', ensure: :present) }.to_not raise_error
      end
    end
  end

  [:advertise].each do |property|
    describe "boolean values of the property '#{property}'" do
      it 'should support true as a value' do
        expect { described_class.new(title: '0.0.0.0 192.168.0.0/24', property => true) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(title: '0.0.0.0 192.168.0.0/24', property => false) }.to_not raise_error
      end

      it 'should contain :true' do
        expect(described_class.new(title: '0.0.0.0 192.168.0.0/24', property => true)[property]).to eq(:true)
      end

      it 'should contain :false' do
        expect(described_class.new(title: '0.0.0.0 192.168.0.0/24', property => false)[property]).to eq(:false)
      end

      it 'should not support foo as a value' do
        expect { described_class.new(title: '0.0.0.0 192.168.0.0/24', property => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'cost' do
    it 'should support 5 as a vallue' do
      expect { described_class.new(title: '0.0.0.0 192.168.0.0/24', cost: 5) }.to_not raise_error
    end

    it 'should not support -5 as a vallue' do
      expect { described_class.new(title: '0.0.0.0 192.168.0.0/24', cost: -5) }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain 100' do
      expect(described_class.new(title: '0.0.0.0 192.168.0.0/24', cost: 100)[:cost]).to eq(100)
    end
  end

  describe 'substitute' do
    it 'should support 192.168.0.0/22 as a value' do
      expect { described_class.new(title: '0.0.0.0 192.168.0.0/24', substitute: '192.168.0.0/22') }.to_not raise_error
    end

    it 'should not support 192.168.256.0/22 as a value' do
      expect { described_class.new(title: '0.0.0.0 192.168.0.0/24', substitute: '192.168.256.0/22') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain 192.168.0.0/22' do
      expect(described_class.new(title: '0.0.0.0 192.168.0.0/24', substitute: '192.168.0.0/22')[:substitute]).to eq('192.168.0.0/22')
    end
  end

  describe 'when autorequiring' do
    it 'should require quagga_ospf_area' do
      ospf_area_range = described_class.new(title: '0.0.0.0 192.168.0.0/24', substitute: '192.168.0.0/22')
      catalog.add_resource ospf_area_range
      catalog.add_resource ospf_area
      reqs = ospf_area_range.autorequire

      expect(reqs.size).to eq(1)
      expect(reqs[0].source).to eq(ospf_area)
      expect(reqs[0].target).to eq(ospf_area_range)
    end
  end
end
