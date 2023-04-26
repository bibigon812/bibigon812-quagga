require 'spec_helper'

describe Puppet::Type.type(:quagga_prefix_list) do
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
    allow(Puppet::Type.type(:quagga_prefix_list)).to receive(:defaultprovider).and_return(providerclass)
  end

  after :each do
    described_class.unprovide(:quagga_prefix_list)
  end

  it 'has :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:action, :prefix, :ge, :le, :proto].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'supports present as a value' do
        expect { described_class.new(name: 'CONNECTED-NETWORK 10', ensure: :present) }.not_to raise_error
      end

      it 'supports absent as a value' do
        expect { described_class.new(name: 'CONNECTED-NETWORK 10', ensure: :absent) }.not_to raise_error
      end

      it 'does not support other values' do
        expect { described_class.new(name: 'CONNECTED-NETWORK 10', ensure: :foo) }.to raise_error Puppet::Error, %r{Invalid value}
      end
    end
  end

  describe 'name' do
    it 'supports \'prefix-list 10\' as a value' do
      expect { described_class.new(name: 'prefix_list 10') }.not_to raise_error
    end

    it 'supports \'prefix-list 100\' as a value' do
      expect { described_class.new(name: 'prefix-list 100') }.not_to raise_error
    end

    it 'does not support \'prefix_list|D\' as a value' do
      expect { described_class.new(name: 'prefix_list|D') }.to raise_error Puppet::Error, %r{Invalid value}
    end
  end

  describe 'action' do
    it 'supports :permit as a value' do
      expect { described_class.new(name: 'foo-prefix 10', action: :permit) }.not_to raise_error
    end

    it 'supports \'permit\' as a value' do
      expect { described_class.new(name: 'foo-prefix 10', action: 'permit') }.not_to raise_error
    end

    it 'supports :deny as a value' do
      expect { described_class.new(name: 'foo-prefix 10', action: :deny) }.not_to raise_error
    end

    it 'supports \'deny\' as a value' do
      expect { described_class.new(name: 'foo-prefix 10', action: 'deny') }.not_to raise_error
    end

    it 'does not support \'reject\' in the string' do
      expect { described_class.new(name: 'foo-prefix 10', action: 'reject') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains :permit' do
      expect(described_class.new(name: 'foo-prefix 10', action: 'permit')[:action]).to eq(:permit)
    end

    it 'contains :deny' do
      expect(described_class.new(name: 'foo-prefix 10', action: 'deny')[:action]).to eq(:deny)
    end
  end

  describe 'prefix' do
    it 'supports \'192.168.0.0/16\' as a value' do
      expect { described_class.new(name: 'foo-prefix 10', prefix: '192.168.0.0/16') }.not_to raise_error
    end

    it 'supports \'172.16.0.0/12\' as a value' do
      expect { described_class.new(name: 'foo-prefix 10', prefix: '172.16.0.0/12') }.not_to raise_error
    end

    it 'supports :any as a value' do
      expect { described_class.new(name: 'foo-prefix 10', prefix: :any) }.not_to raise_error
    end

    it 'supports \'any\' as a value' do
      expect { described_class.new(name: 'foo-prefix 10', prefix: 'any') }.not_to raise_error
    end

    it 'does not support \'reject\' in the string' do
      expect { described_class.new(name: 'foo-prefix 10', prefix: 'reject') }.to  raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains \'192.168.0.0/16\'' do
      expect(described_class.new(name: 'foo-prefix 10', prefix: '192.168.0.0/16')[:prefix]).to eq('192.168.0.0/16')
    end

    it 'contains \'any\'' do
      expect(described_class.new(name: 'foo-prefix 10', prefix: 'any')[:prefix]).to eq('any')
    end
  end

  describe 'proto' do
    it 'supports \'ip\' as a value' do
      expect { described_class.new(name: 'foo-prefix 10', proto: 'ip') }.not_to raise_error
    end

    it 'supports \'ipv6\' as a value' do
      expect { described_class.new(name: 'foo-prefix 10', proto: 'ipv6') }.not_to raise_error
    end

    it 'supports :ip as a value' do
      expect { described_class.new(name: 'foo-prefix 10', proto: :ip) }.not_to raise_error
    end

    it 'supports :ipv6 as a value' do
      expect { described_class.new(name: 'foo-prefix 10', proto: :ipv6) }.not_to raise_error
    end

    it 'does not support :ipv5 in the string' do
      expect { described_class.new(name: 'foo-prefix 10', proto: :ipv5) }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains \'ip\'' do
      expect(described_class.new(name: 'foo-prefix 10', proto: 'ip')[:proto]).to eq(:ip)
    end

    it 'contains :ipv6' do
      expect(described_class.new(name: 'foo-prefix 10', proto: :ipv6)[:proto]).to eq(:ipv6)
    end
  end

  [:ge, :le].each do |property|
    describe property.to_s do
      it 'supports 16 as a value' do
        expect { described_class.new(name: 'foo-prefix 10', property => 16) }.not_to raise_error
      end

      it 'supports 8 as a value' do
        expect { described_class.new(name: 'foo-prefix 10', property => 8) }.not_to raise_error
      end

      it 'does not support \'reject\' as a value' do
        expect { described_class.new(name: 'foo-prefix 10', property => '10') }.to  raise_error Puppet::Error, %r{Invalid value}
      end

      it 'contains \'24\'' do
        expect(described_class.new(name: 'foo-prefix 10', property => 24)[property]).to eq(24)
      end

      it 'contains 16' do
        expect(described_class.new(name: 'foo-prefix 10', property => 13)[property]).to eq(13)
      end
    end
  end
end
