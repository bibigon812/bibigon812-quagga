require 'spec_helper'

describe Puppet::Type.type(:quagga_access_list) do
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
    Puppet::Type.type(:quagga_access_list).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_access_list)
  end

  it 'should have number be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:remark, :rules].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'rules' do
    it 'should support permit any' do
      expect { described_class.new(name: '1', rules: 'permit any') }.to_not raise_error
    end

    it 'should support permit ip any any' do
      expect { described_class.new(name: '1', rules: 'permit ip any any') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support permit any' do
      expect { described_class.new(name: '100', rules: 'permit any') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should support permit ip any any' do
      expect { described_class.new(name: '100', rules: 'permit ip any any') }.to_not raise_error
    end
  end

end
