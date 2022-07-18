require 'spec_helper'

describe Puppet::Type.type(:quagga_logging) do
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
    Puppet::Type.type(:quagga_logging).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_logging)
  end

  it 'has :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider ].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:filename, :level ].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when autorequiring' do
    it 'requires zebra services' do
      described_resource = described_class.new(name: 'syslog')
      catalog.add_resource zebra
      catalog.add_resource described_resource
      reqs = described_resource.autorequire

      expect(reqs.size).to eq(1)
      expect(reqs[0].source).to eq(zebra)
      expect(reqs[0].target).to eq(described_resource)
    end
  end
end
