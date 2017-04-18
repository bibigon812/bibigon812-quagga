require 'spec_helper'

describe Puppet::Type.type(:prefix_list) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:prefix_list) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:prefix_list)
  end

  it 'should have :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe "when validating attributes" do
    [ :name, :provider ].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [ :description, :seq ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'CONNECTED-NETWORK', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'CONNECTED-NETWORK', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'CONNECTED-NETWORK', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'description' do
    it 'should support a string as a value' do
      expect { described_class.new(:name => 'foo-prefix', :description => 'foo prefix-list') }.to_not raise_error
    end

    it 'should not support a string over 80 chars' do
      expect { described_class.new(:name => 'foo-prefix', :description => 'foo prefix list foo prefix list foo prefix list foo prefix list foo prefix list foo prefix list foo prefix list foo prefix list foo prefix list foo prefix list') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support a dot in the string' do
      expect { described_class.new(:name => 'foo-prefix', :description => 'foo.prefix-list') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain \'foo prefix-list\'' do
      expect(described_class.new(:name => 'foo-prefix', :description => 'foo prefix-list')[:description]).to eq('foo prefix-list')
    end
  end
end
