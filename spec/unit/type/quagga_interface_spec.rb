require 'spec_helper'

describe Puppet::Type.type(:quagga_interface) do
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
  let(:catalog) { Puppet::Resource::Catalog.new }

  before :each do
    Puppet::Type.type(:quagga_interface).stubs(:defaultprovider).returns providerclass
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

    [ :bandwidth, :link_detect, ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ip_address' do
      it 'should support 10.0.0.1/24 as a value' do
        expect { described_class.new(:name => 'foo', :ip_address => '10.0.0.1/24') }.to_not raise_error
      end

      it 'should not support 500.0.0.1/24 as a value' do
        expect { described_class.new(:name => 'foo', :ip_address => '500.0.0.1/24') }.to raise_error Puppet::Error, /Not a valid ip address/
      end

      it 'should not support 10.0.0.1 as a value' do
        expect { described_class.new(:name => 'foo', :ip_address => '10.0.0.1') }.to raise_error Puppet::Error, /Prefix length is not specified/
      end

      it 'should contain 10.0.0.1' do
        expect(described_class.new(:name => 'foo', :ip_address => '10.0.0.1/24')[:ip_address]).to eq(['10.0.0.1/24'])
      end
    end

    [ :link_detect ].each do |property|
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
  end

  describe 'when autorequiring' do
    it 'should require zebra service' do
      interface = described_class.new(:name => 'eth0')
      catalog.add_resource zebra
      catalog.add_resource interface
      reqs = interface.autorequire

      expect(reqs.size).to eq(1)
      expect(reqs[0].source).to eq(zebra)
      expect(reqs[0].target).to eq(interface)
    end
  end
end
