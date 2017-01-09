require 'spec_helper'

describe Puppet::Type.type(:network_interface) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:network_interface) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:network_interface)
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

    [:type].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe "when validating values" do

    describe "ensure" do
      it "should support up as a value for ensure" do
        expect { described_class.new(:name => 'foo', :ensure => :up) }.to_not raise_error
      end

      it "should support down as a value for ensure" do
        expect { described_class.new(:name => 'foo', :ensure => :down) }.to_not raise_error
      end

      it "should support absent as a value for ensure" do
        expect { described_class.new(:name => 'foo', :ensure => :absent) }.to_not raise_error
      end

      it "should not support other values" do
        expect { described_class.new(:name => 'foo', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'type' do
      it 'should contain bonding' do
        expect(described_class.new(:name => 'bond0', :type => 'bonding')[:type]).to match Regexp.new('bonding')
      end

      it 'should contain ethernet' do
        expect(described_class.new(:name => 'eth0', :type => 'ethernet')[:type]).to match Regexp.new('ethernet')
      end

      it 'should contain bridge' do
        expect(described_class.new(:name => 'br0', :type => 'bridge')[:type]).to match Regexp.new('bridge')
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'foo', :type => 'foo') }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end
end
