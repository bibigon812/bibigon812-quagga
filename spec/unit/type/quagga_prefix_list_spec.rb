require 'spec_helper'

describe Puppet::Type.type(:quagga_prefix_list) do
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
    Puppet::Type.type(:quagga_bgp_as_path).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_prefix_list)
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

    [:action, :prefix, :ge, :le, :protocol].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'CONNECTED-NETWORK 10', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'CONNECTED-NETWORK 10', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'CONNECTED-NETWORK 10', :ensure => :foo) }.to  raise_error Puppet::Error, /Invalid value/
      end
    end
  end

  describe 'name' do
    it 'should support \'prefix-list 10\' as a value' do
      expect { described_class.new(:name => 'prefix_list 10') }.to_not raise_error
    end

    it 'should support \'prefix-list 100\' as a value' do
      expect { described_class.new(:name => 'prefix-list 100') }.to_not raise_error
    end

    it 'should not support \'prefix_list|D\' as a value' do
      expect { described_class.new(:name => 'prefix_list|D') }.to  raise_error Puppet::Error, /Invalid value/
    end
  end

  describe 'action' do
    it 'should support :permit as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :action => :permit) }.to_not raise_error
    end

    it 'should support \'permit\' as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :action => 'permit') }.to_not raise_error
    end

    it 'should support :deny as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :action => :deny) }.to_not raise_error
    end

    it 'should support \'deny\' as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :action => 'deny') }.to_not raise_error
    end

    it 'should not support \'reject\' in the string' do
      expect { described_class.new(:name => 'foo-prefix 10', :action => 'reject') }.to  raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain :permit' do
      expect(described_class.new(:name => 'foo-prefix 10', :action => 'permit')[:action]).to eq(:permit)
    end

    it 'should contain :deny' do
      expect(described_class.new(:name => 'foo-prefix 10', :action => 'deny')[:action]).to eq(:deny)
    end
  end

  describe 'prefix' do
    it 'should support \'192.168.0.0/16\' as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :prefix => '192.168.0.0/16') }.to_not raise_error
    end

    it 'should support \'172.16.0.0/12\' as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :prefix => '172.16.0.0/12') }.to_not raise_error
    end

    it 'should support :any as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :prefix => :any) }.to_not raise_error
    end

    it 'should support \'any\' as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :prefix => 'any') }.to_not raise_error
    end

    it 'should not support \'reject\' in the string' do
      expect { described_class.new(:name => 'foo-prefix 10', :prefix => 'reject') }.to  raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain \'192.168.0.0/16\'' do
      expect(described_class.new(:name => 'foo-prefix 10', :prefix => '192.168.0.0/16')[:prefix]).to eq('192.168.0.0/16')
    end

    it 'should contain \'any\'' do
      expect(described_class.new(:name => 'foo-prefix 10', :prefix => 'any')[:prefix]).to eq('any')
    end
  end

  describe 'protocol' do
    it 'should support \'ip\' as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :protocol => 'ip') }.to_not raise_error
    end

    it 'should support \'ipv6\' as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :protocol => 'ipv6') }.to_not raise_error
    end

    it 'should support :ip as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :protocol => :ip) }.to_not raise_error
    end

    it 'should support :ipv6 as a value' do
      expect { described_class.new(:name => 'foo-prefix 10', :protocol => :ipv6) }.to_not raise_error
    end

    it 'should not support :ipv5 in the string' do
      expect { described_class.new(:name => 'foo-prefix 10', :protocol => :ipv5) }.to  raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain \'ip\'' do
      expect(described_class.new(:name => 'foo-prefix 10', :protocol => 'ip')[:protocol]).to eq(:ip)
    end

    it 'should contain :ipv6' do
      expect(described_class.new(:name => 'foo-prefix 10', :protocol => :ipv6)[:protocol]).to eq(:ipv6)
    end
  end

  [:ge, :le].each do |property|
    describe "#{property}" do
      it 'should support \'24\' as a value' do
        expect { described_class.new(:name => 'foo-prefix 10', property => '24') }.to_not raise_error
      end

      it 'should support 16 as a value' do
        expect { described_class.new(:name => 'foo-prefix 10', property => 16) }.to_not raise_error
      end

      it 'should support 8 as a value' do
        expect { described_class.new(:name => 'foo-prefix 10', property => 8) }.to_not raise_error
      end

      it 'should not support \'reject\' as a value' do
        expect { described_class.new(:name => 'foo-prefix 10', property => 'reject') }.to  raise_error Puppet::Error, /Invalid value/
      end

      it 'should contain \'24\'' do
        expect(described_class.new(:name => 'foo-prefix 10', property => '24')[property]).to eq(24)
      end

      it 'should contain 16' do
        expect(described_class.new(:name => 'foo-prefix 10', property => 16)[property]).to eq(16)
      end
    end
  end
end
