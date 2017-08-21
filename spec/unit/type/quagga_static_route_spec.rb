require 'spec_helper'

describe Puppet::Type.type(:quagga_static_route) do
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
    Puppet::Type.type(:quagga_static_route).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_static_route)
  end

  it 'should have prefix, nexthop be its namevar' do
    expect(described_class.key_attributes).to eq([:prefix, :nexthop])
  end

  describe "when validating attributes" do
    [:prefix, :nexthop, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:distance, :option].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:title => '192.168.0.0/16', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:title => '192.168.0.0/16', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:title => '192.168.0.0/16', :ensure => :foo) }.to raise_error Puppet::Error, /Invalid value/
      end
    end
  end

  describe 'nexthop' do
    it 'should support Null0 as a value' do
      expect { described_class.new(:title => '192.168.0.0/16', :nexthop => 'Null0') }.to_not raise_error
    end

    it 'should support 192.168.1.1 as a value' do
      expect { described_class.new(:title => '192.168.0.0/16', :nexthop => '192.168.1.1') }.to_not raise_error
    end

    it 'should support 192.168.1.1 as a value' do
      expect { described_class.new(:title => '192.168.0.0/16', :nexthop => '192.168.1.1') }.to_not raise_error
    end

    it 'should contain Null0' do
      expect(described_class.new(:title => '192.168.0.0/16', :nexthop => 'Null0')[:nexthop]).to eq('Null0')
    end
  end

  describe 'distance' do
    it 'should support Null0 as a value' do
      expect { described_class.new(:title => '192.168.0.0/16', :distance => 100) }.to_not raise_error
    end

    it 'should support 192.168.1.1 as a value' do
      expect { described_class.new(:title => '192.168.0.0/16', :distance => '200') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should support 192.168.1.1 as a value' do
      expect(described_class.new(:title => '192.168.0.0/16', :distance => 50)[:distance]).to eq(50)
    end
  end

  describe 'option' do
    it 'should support blackhole as a value' do
      expect { described_class.new(title: '192.168.0.0/16 10.0.0.1', option: :blackhole) }.to_not raise_error
    end

    it 'should support reject as a value' do
      expect { described_class.new(title: '192.168.0.0/16 10.0.0.1', option: :reject) }.to_not raise_error
    end

    it 'should not support foo as a value' do
      expect { described_class.new(title: '192.168.0.0/16 10.0.0.1', option: :foo) }.to raise_error Puppet::Error, /Invalid value/
    end
  end
end
