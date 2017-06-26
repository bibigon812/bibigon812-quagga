require 'spec_helper'

describe Puppet::Type.type(:quagga_global) do
  let(:provider) do
    @provider_class = describe_class.provide(:quagga_ospf) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:quagga_ospf)
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

    [:hostname, :password, :enable_password, :line_vty, :service_password_encryption,
    :ip_forwarding, :ipv6_forwarding, :ip_multicast_routing].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'name' do
    it 'should support ospf as a value' do
      expect { described_class.new(:name => 'foo') }.to_not raise_error
    end

    it 'should not support foo as a value' do
      expect { described_class.new(:name => 'hostname.example.com') }.to_not raise_error
    end
  end

  [:line_vty, :service_password_encryption, :ip_forwarding, :ipv6_forwarding, :ip_multicast_routing,
  ].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'should support \'true\' as a value' do
        expect { described_class.new(:name => 'hostname.example.com', property => 'true') }.to_not raise_error
      end

      it 'should support :true as a value' do
        expect { described_class.new(:name => 'hostname.example.com', property => :true) }.to_not raise_error
      end

      it 'should support true as a value' do
        expect { described_class.new(:name => 'hostname.example.com', property => true) }.to_not raise_error
      end

      it 'should support \'false\' as a value' do
        expect { described_class.new(:name => 'hostname.example.com', property => 'false') }.to_not raise_error
      end

      it 'should support :false as a value' do
        expect { described_class.new(:name => 'hostname.example.com', property => :false) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(:name => 'hostname.example.com', property => false) }.to_not raise_error
      end

      it 'should not support :enabled as a value' do
        expect { described_class.new(:name => 'hostname.example.com', property => :enabled) }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should not support \'disabled\' as a value' do
        expect { described_class.new(:name => 'hostname.example.com', property => 'disabled') }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should contain :true' do
        expect(described_class.new(:name => 'hostname.example.com', property => 'true')[property]).to eq(:true)
      end

      it 'should contain :true' do
        expect(described_class.new(:name => 'hostname.example.com', property => true)[property]).to eq(:true)
      end

      it 'should contain :false' do
        expect(described_class.new(:name => 'hostname.example.com', property => 'false')[property]).to eq(:false)
      end

      it 'should contain :false' do
        expect(described_class.new(:name => 'hostname.example.com', property => false)[property]).to eq(:false)
      end
    end
  end

  describe 'hostname' do
    it 'should support \'\' as a value' do
      expect { described_class.new(:name => 'hostname.example.com', :hostname => '') }.to_not raise_error
    end

    it 'should support host1.example.com as a value' do
      expect { described_class.new(:name => 'hostname.example.com', :hostname => 'host1.example.com') }.to_not raise_error
    end

    it 'should contain hostname.example.com' do
      expect(described_class.new(:name => 'hostname.example.com')[:hostname]).to eq('hostname.example.com')
    end

    it 'should contain hostname.example.com' do
      expect(described_class.new(:name => 'hostname.example.com', :hostname => '')[:hostname]).to eq('hostname.example.com')
    end

    it 'should contain host1.example.com' do
      expect(described_class.new(:name => 'hostname.example.com', :hostname => 'host1.example.com')[:hostname]).to eq('host1.example.com')
    end
  end
end