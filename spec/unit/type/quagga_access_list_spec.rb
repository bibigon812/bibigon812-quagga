require 'spec_helper'

describe Puppet::Type.type(:quagga_access_list) do
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
    allow(Puppet::Type.type(:quagga_access_list)).to receive(:defaultprovider).and_return(providerclass)
  end

  after :each do
    described_class.unprovide(:quagga_access_list)
  end

  it 'has number be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:remark, :rules].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'rules' do
    it 'supports permit any' do
      expect { described_class.new(name: '1', rules: 'permit any') }.not_to raise_error
    end

    it 'does not supports permit ip any any for the first entry' do
      expect { described_class.new(name: '1', rules: 'permit ip any any') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'does not support permit any' do
      expect { described_class.new(name: '100', rules: 'permit any') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'supports permit ip any any for other entries' do
      expect { described_class.new(name: '100', rules: 'permit ip any any') }.not_to raise_error
    end
  end
end
