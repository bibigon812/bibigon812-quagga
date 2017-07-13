require 'spec_helper'

describe Puppet::Type.type(:quagga_pim_router) do
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

  before :each do
    Puppet::Type.type(:quagga_pim_router).stubs(:defaultprovider).returns providerclass
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

    [:ip_multicast_routing].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'title' do
    it 'should support pim as a value' do
      expect { described_class.new(:name => 'pim') }.to_not raise_error
    end

    it 'should not support foo as a value' do
      expect { described_class.new(:name => 'foo') }.to_not raise_error
    end
  end

  [:ip_multicast_routing].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'should support \'true\' as a value' do
        expect { described_class.new(:name => 'pim', property => 'true') }.to_not raise_error
      end

      it 'should support :true as a value' do
        expect { described_class.new(:name => 'pim', property => :true) }.to_not raise_error
      end

      it 'should support true as a value' do
        expect { described_class.new(:name => 'pim', property => true) }.to_not raise_error
      end

      it 'should support \'false\' as a value' do
        expect { described_class.new(:name => 'pim', property => 'false') }.to_not raise_error
      end

      it 'should support :false as a value' do
        expect { described_class.new(:name => 'pim', property => :false) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(:name => 'pim', property => false) }.to_not raise_error
      end

      it 'should not support :enabled as a value' do
        expect { described_class.new(:name => 'pim', property => :enabled) }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should not support \'disabled\' as a value' do
        expect { described_class.new(:name => 'pim', property => 'disabled') }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should contain :true' do
        expect(described_class.new(:name => 'pim', property => 'true')[property]).to eq(:true)
      end

      it 'should contain :true' do
        expect(described_class.new(:name => 'pim', property => true)[property]).to eq(:true)
      end

      it 'should contain :false' do
        expect(described_class.new(:name => 'pim', property => 'false')[property]).to eq(:false)
      end

      it 'should contain :false' do
        expect(described_class.new(:name => 'pim', property => false)[property]).to eq(:false)
      end
    end
  end
end
