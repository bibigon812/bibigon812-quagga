require 'spec_helper'

describe Puppet::Type.type(:quagga_global) do
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
    Puppet::Type.type(:quagga_global).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_ospf)
  end

  it 'has :name be its namevar' do
    expect(described_class.key_attributes).to eq([:hostname])
  end

  describe 'when validating attributes' do
    [:hostname, :provider].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:password, :enable_password, :line_vty, :service_password_encryption,
     :ip_forwarding, :ipv6_forwarding].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'title' do
    it 'supports ospf as a value' do
      expect { described_class.new(name: 'foo') }.not_to raise_error
    end

    it 'does not support foo as a value' do
      expect { described_class.new(name: 'hostname.example.com') }.not_to raise_error
    end
  end

  [:line_vty, :service_password_encryption, :ip_forwarding, :ipv6_forwarding].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'supports \'true\' as a value' do
        expect { described_class.new(name: 'hostname.example.com', property => 'true') }.not_to raise_error
      end

      it 'supports :true as a value' do
        expect { described_class.new(name: 'hostname.example.com', property => :true) }.not_to raise_error
      end

      it 'supports true as a value' do
        expect { described_class.new(name: 'hostname.example.com', property => true) }.not_to raise_error
      end

      it 'supports \'false\' as a value' do
        expect { described_class.new(name: 'hostname.example.com', property => 'false') }.not_to raise_error
      end

      it 'supports :false as a value' do
        expect { described_class.new(name: 'hostname.example.com', property => :false) }.not_to raise_error
      end

      it 'supports false as a value' do
        expect { described_class.new(name: 'hostname.example.com', property => false) }.not_to raise_error
      end

      it 'does not support :enabled as a value' do
        expect { described_class.new(name: 'hostname.example.com', property => :enabled) }.to raise_error(Puppet::Error, %r{Invalid value})
      end

      it 'does not support \'disabled\' as a value' do
        expect { described_class.new(name: 'hostname.example.com', property => 'disabled') }.to raise_error(Puppet::Error, %r{Invalid value})
      end

      it 'contains :true when passed string "true"' do
        expect(described_class.new(name: 'hostname.example.com', property => 'true')[property]).to eq(:true)
      end

      it 'contains :true when passed value true' do
        expect(described_class.new(name: 'hostname.example.com', property => true)[property]).to eq(:true)
      end

      it 'contains :false when passed string "false"' do
        expect(described_class.new(name: 'hostname.example.com', property => 'false')[property]).to eq(:false)
      end

      it 'contains :false when passed value false' do
        expect(described_class.new(name: 'hostname.example.com', property => false)[property]).to eq(:false)
      end
    end
  end

  describe 'hostname' do
    it 'supports \'\' as a value' do
      expect { described_class.new(name: 'hostname.example.com', hostname: '') }.not_to raise_error
    end

    it 'supports host1.example.com as a value' do
      expect { described_class.new(name: 'hostname.example.com', hostname: 'host1.example.com') }.not_to raise_error
    end

    it 'contains hostname.example.com' do
      expect(described_class.new(name: 'hostname.example.com')[:hostname]).to eq('hostname.example.com')
    end

    it 'accepts an empty hostname string and returns an empty string' do
      expect(described_class.new(name: 'hostname.example.com', hostname: '')[:hostname]).to eq('')
    end

    it 'contains host1.example.com' do
      expect(described_class.new(name: 'hostname.example.com', hostname: 'host1.example.com')[:hostname]).to eq('host1.example.com')
    end
  end
end
