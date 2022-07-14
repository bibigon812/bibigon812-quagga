require 'spec_helper'

describe Puppet::Type.type(:quagga_pim_interface) do
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
  let(:pimd) { Puppet::Type.type(:service).new(name: 'pimd') }
  let(:catalog) { Puppet::Resource::Catalog.new }

  before :each do
    described_class.stubs(:defaultprovider).returns providerclass
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

    [
      :igmp, :pim_ssm, :igmp_query_interval, :igmp_query_max_response_time_dsec,
      :multicast
    ].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when autorequiring' do
    it 'requires zebra and pimd services' do
      interface = described_class.new(name: 'eth0')
      catalog.add_resource zebra
      catalog.add_resource pimd
      catalog.add_resource interface
      reqs = interface.autorequire

      expect(reqs.size).to eq(2)
      expect(reqs[0].source).to eq(zebra)
      expect(reqs[0].target).to eq(interface)
      expect(reqs[1].source).to eq(pimd)
      expect(reqs[1].target).to eq(interface)
    end
  end
end
