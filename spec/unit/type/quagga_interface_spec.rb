require 'spec_helper'

describe Puppet::Type.type(:quagga_interface) do
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
  let(:catalog) { Puppet::Resource::Catalog.new }

  before :each do
    Puppet::Type.type(:quagga_interface).stubs(:defaultprovider).returns providerclass
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

    [ :bandwidth, :link_detect ].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ip_address' do
      it 'supports 10.0.0.1/24 as a value' do
        expect { described_class.new(name: 'foo', ip_address: '10.0.0.1/24') }.not_to raise_error
      end

      it 'does not support 500.0.0.1/24 as a value' do
        expect { described_class.new(name: 'foo', ip_address: '500.0.0.1/24') }.to raise_error Puppet::Error, %r{Not a valid ip address}
      end

      it 'does not support 10.0.0.1 as a value' do
        expect { described_class.new(name: 'foo', ip_address: '10.0.0.1') }.to raise_error Puppet::Error, %r{Prefix length is not specified}
      end

      it 'contains 10.0.0.1' do
        expect(described_class.new(name: 'foo', ip_address: '10.0.0.1/24')[:ip_address]).to eq(['10.0.0.1/24'])
      end
    end

    [ :link_detect ].each do |property|
      describe property.to_s do
        it 'supports true as a value' do
          expect { described_class.new(name: 'foo', property => true) }.not_to raise_error
        end

        it 'supports :true as a value' do
          expect { described_class.new(name: 'foo', property => :true) }.not_to raise_error
        end

        it 'supports "xtrue" as a value' do
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
  end

  describe 'when autorequiring' do
    it 'requires zebra service' do
      interface = described_class.new(name: 'eth0')
      catalog.add_resource zebra
      catalog.add_resource interface
      reqs = interface.autorequire

      expect(reqs.size).to eq(1)
      expect(reqs[0].source).to eq(zebra)
      expect(reqs[0].target).to eq(interface)
    end
  end
end
