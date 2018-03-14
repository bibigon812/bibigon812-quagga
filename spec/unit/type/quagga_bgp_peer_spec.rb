require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_peer) do
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
    Puppet::Type.type(:quagga_bgp_peer).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_bgp_peer)
  end

  it 'should have :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:local_as, :passive, :peer_group, :remote_as, :shutdown].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => '192.168.1.1', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => '192.168.1.1', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support foo values' do
        expect { described_class.new(:name => '192.168.1.1', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'name' do
    it 'should support 192.168.1.1 as a value' do
      expect { described_class.new(:name => '192.168.1.1') }.to_not raise_error
    end

    it 'should support 10.1.1.1 as a value' do
      expect { described_class.new(:name => '10.1.1.1') }.to_not raise_error
    end

    it 'should support 10.1.1.0 as a value' do
      expect { described_class.new(:name => '10.1.1.0') }.to_not raise_error
    end

    it 'should support 2aff::1 as a value' do
      expect { described_class.new(:name => '2aff::1') }.to_not raise_error
    end

    it 'should not support 10.256.0.0 as a value' do
      expect { described_class.new(:name => '100:10.256.0.0') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  [:passive,].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'should support \'true\' as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => 'true') }.to_not raise_error
      end

      it 'should support :true as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => :true) }.to_not raise_error
      end

      it 'should support true as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => true) }.to_not raise_error
      end

      it 'should support \'false\' as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => 'false') }.to_not raise_error
      end

      it 'should support :false as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => :false) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => false) }.to_not raise_error
      end

      it 'should not support :enabled as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => :enabled) }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should not support \'disabled\' as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => 'disabled') }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should contain :true' do
        expect(described_class.new(:name => '192.168.1.1', property => 'true')[property]).to eq(:true)
      end

      it 'should contain :true' do
        expect(described_class.new(:name => '192.168.1.1', property => true)[property]).to eq(:true)
      end

      it 'should contain :false' do
        expect(described_class.new(:name => '192.168.1.1', property => 'false')[property]).to eq(:false)
      end

      it 'should contain :false' do
        expect(described_class.new(:name => '192.168.1.1', property => false)[property]).to eq(:false)
      end
    end
  end

  describe 'peer_group' do
    it 'should support \'true\' as a value' do
      expect { described_class.new(:name => '192.168.1.1', :peer_group => 'true') }.to_not raise_error
    end

    it 'should support :true as a value' do
      expect { described_class.new(:name => '192.168.1.1', :peer_group => :true) }.to_not raise_error
    end

    it 'should support true as a value' do
      expect { described_class.new(:name => '192.168.1.1', :peer_group => true) }.to_not raise_error
    end

    it 'should support \'false\' as a value' do
      expect { described_class.new(:name => '192.168.1.1', :peer_group => 'false') }.to_not raise_error
    end

    it 'should support :false as a value' do
      expect { described_class.new(:name => '192.168.1.1', :peer_group => :false) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '192.168.1.1', :peer_group => false) }.to_not raise_error
    end

    it 'should support peer_group as a value' do
      expect { described_class.new(:name => '192.168.1.1', :peer_group => 'peer_group') }.to_not raise_error
    end

    it 'should support peer_group_1 as a value' do
      expect { described_class.new(:name => '192.168.1.1', :peer_group => :peer_group_1) }.to_not raise_error
    end

    it 'should not support 9-allow as a value' do
      expect { described_class.new(:name => '192.168.1.1', :peer_group => '9-allow') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain true' do
      expect(described_class.new(:name => '192.168.1.1', :peer_group => 'true')[:peer_group]).to eq(:true)
    end

    it 'should contain true' do
      expect(described_class.new(:name => '192.168.1.1', :peer_group => true)[:peer_group]).to eq(:true)
    end

    it 'should contain fasle' do
      expect(described_class.new(:name => '192.168.1.1', :peer_group => 'false')[:peer_group]).to eq(:false)
    end

    it 'should contain :false' do
      expect(described_class.new(:name => '192.168.1.1', :peer_group => false)[:peer_group]).to eq(:false)
    end

    it 'should contain peer_group' do
      expect(described_class.new(:name => '192.168.1.1', :peer_group => 'peer_group')[:peer_group]).to eq('peer_group')
    end

    it 'should contain peer_group_1' do
      expect(described_class.new(:name => '192.168.1.1', :peer_group => 'peer_group_1')[:peer_group]).to eq('peer_group_1')
    end
  end

  [:local_as, :remote_as].each do |property|
    describe "#{property}" do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => '100') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should support 100 as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => 0) }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should not support AS100 as a value' do
        expect { described_class.new(:name => '192.168.1.1', property => 'AS100') }.to raise_error(Puppet::Error, /Invalid value/)
      end

      it 'should contain 100' do
        expect(described_class.new(:name => '192.168.1.1', property => 100)[property]).to eq(100)
      end
    end
  end

  describe 'update_source' do
    it 'should support eth1 as a value' do
      expect { described_class.new(:name => '192.168.1.1', :update_source => 'eth1') }.to_not raise_error
    end

    it 'should support 10.0.0.1 as a value' do
      expect { described_class.new(:name => '192.168.1.1', :update_source => '10.0.0.1') }.to_not raise_error
    end

    it 'should not support 0bond0 as a value' do
      expect { described_class.new(:name => '192.168.1.1', :update_source => '0bond0') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 10.256.0.1 as a value' do
      expect { described_class.new(:name => '192.168.1.1', :update_source => '10.256.0.1') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain eth0' do
      expect(described_class.new(:name => '192.168.1.1', :update_source => 'eth0')[:update_source]).to eq('eth0')
    end

    it 'should contain 10.0.0.2' do
      expect(described_class.new(:name => '192.168.1.1', :update_source => '10.0.0.2')[:update_source]).to eq('10.0.0.2')
    end
  end

  describe 'password' do
    it 'should support string as a value' do
      expect { described_class.new(name: '192.168.1.1', password: 'QWRF$345!#@$') }.to_not raise_error
    end

    it 'should contain QWRF$345!#@$' do
      expect(described_class.new(:name => '192.168.1.1', password: 'QWRF$345!#@$')[:password]).to eq('QWRF$345!#@$')
    end
  end
end
