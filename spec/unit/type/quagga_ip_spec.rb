require 'spec_helper'

describe Puppet::Type.type(:quagga_ip) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:pim) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:pim)
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

    [:forwarding, :multicast_routing].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'name' do
    it 'should support quagga as a value' do
      expect { described_class.new(:name => 'quagga') }.to_not raise_error
    end

    it 'should not support foo as a value' do
      expect { described_class.new(:name => 'foo') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  describe 'multicast_routing' do
    it 'should support true as a value' do
      expect { described_class.new(:name => 'quagga', :multicast_routing => true) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => 'quagga', :multicast_routing => false) }.to_not raise_error
    end

    it 'should contain :true' do
      expect(described_class.new(:name => 'quagga', :multicast_routing => true)[:multicast_routing]).to eq(:true)
    end

    it 'should contain :false' do
      expect(described_class.new(:name => 'quagga', :multicast_routing => false)[:multicast_routing]).to eq(:false)
    end

    it 'should not support foo as a value' do
      expect { described_class.new(:name => 'quagga', :multicast_routing => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  describe 'forwarding' do
    it 'should support true as a value' do
      expect { described_class.new(:name => 'quagga', :forwarding => true) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => 'quagga', :forwarding => false) }.to_not raise_error
    end

    it 'should contain :true' do
      expect(described_class.new(:name => 'quagga', :forwarding => true)[:forwarding]).to eq(:true)
    end

    it 'should contain :false' do
      expect(described_class.new(:name => 'quagga', :forwarding => false)[:forwarding]).to eq(:false)
    end

    it 'should not support foo as a value' do
      expect { described_class.new(:name => 'quagga', :forwarding => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end
end
