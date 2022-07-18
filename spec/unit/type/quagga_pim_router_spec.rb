require 'spec_helper'

describe Puppet::Type.type(:quagga_pim_router) do
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
    Puppet::Type.type(:quagga_pim_router).stubs(:defaultprovider).returns providerclass
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

    [:ip_multicast_routing].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'title' do
    it 'supports pim as a value' do
      expect { described_class.new(name: 'pim') }.not_to raise_error
    end

    it 'does not support foo as a value' do
      expect { described_class.new(name: 'foo') }.not_to raise_error
    end
  end

  [:ip_multicast_routing].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'supports \'true\' as a value' do
        expect { described_class.new(name: 'pim', property => 'true') }.not_to raise_error
      end

      it 'supports :true as a value' do
        expect { described_class.new(name: 'pim', property => :true) }.not_to raise_error
      end

      it 'supports true as a value' do
        expect { described_class.new(name: 'pim', property => true) }.not_to raise_error
      end

      it 'supports \'false\' as a value' do
        expect { described_class.new(name: 'pim', property => 'false') }.not_to raise_error
      end

      it 'supports :false as a value' do
        expect { described_class.new(name: 'pim', property => :false) }.not_to raise_error
      end

      it 'supports false as a value' do
        expect { described_class.new(name: 'pim', property => false) }.not_to raise_error
      end

      it 'does not support :enabled as a value' do
        expect { described_class.new(name: 'pim', property => :enabled) }.to raise_error(Puppet::Error, %r{Invalid value})
      end

      it 'does not support \'disabled\' as a value' do
        expect { described_class.new(name: 'pim', property => 'disabled') }.to raise_error(Puppet::Error, %r{Invalid value})
      end

      it 'contains :true when passed string "true"' do
        expect(described_class.new(name: 'pim', property => 'true')[property]).to eq(:true)
      end

      it 'contains :true when passed value true' do
        expect(described_class.new(name: 'pim', property => true)[property]).to eq(:true)
      end

      it 'contains :false when passed string "false"' do
        expect(described_class.new(name: 'pim', property => 'false')[property]).to eq(:false)
      end

      it 'contains :false when passed value false' do
        expect(described_class.new(name: 'pim', property => false)[property]).to eq(:false)
      end
    end
  end
end
