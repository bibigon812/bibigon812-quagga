require 'spec_helper'

describe Puppet::Type.type(:bgp_neighbor) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:bgp_neighbor) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:bgp_neighbor)
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

    [:allow_as_in, :default_originate, :local_as, :next_hop_self, :peer_group, :prefix_list_in, :prefix_list_out,
     :remote_as, :route_map_export, :route_map_import, :route_map_in, :route_map_out].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => '65000:192.168.1.1', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => '65000:192.168.1.1', :ensure => :absent) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => '65000:192.168.1.1', :ensure => :activate) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => '65000:192.168.1.1', :ensure => :shutdown) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => '65000:192.168.1.1', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'name' do
    it 'should support 65000:192.168.1.1 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1') }.to_not raise_error
    end

    it 'should support 10.1.1.1 as a value' do
      expect { described_class.new(:name => '65000:10.1.1.1') }.to_not raise_error
    end

    it 'should support 10.1.1.0 as a value' do
      expect { described_class.new(:name => '65000:10.1.1.0') }.to_not raise_error
    end


    it 'should not support 10.256.0.0 as a value' do
      expect { described_class.new(:name => '100:10.256.0.0') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  describe 'allow_as_in' do
    it 'should support \'1\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :allow_as_in => '1') }.to_not raise_error
    end

    it 'should support 1 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :allow_as_in => 1) }.to_not raise_error
    end

    it 'should not support 0 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :allow_as_in => 0) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support -1 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :allow_as_in => -1) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support \'a lot\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :allow_as_in => 'a lot') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain 1' do
      expect(described_class.new(:name => '65000:192.168.1.1', :allow_as_in => '1')[:allow_as_in]).to eq(1)
    end

    it 'should contain 2' do
      expect(described_class.new(:name => '65000:192.168.1.1', :allow_as_in => 2)[:allow_as_in]).to eq(2)
    end

    it 'should contain 5' do
      expect(described_class.new(:name => '65000:192.168.1.1', :allow_as_in => 5)[:allow_as_in]).to eq(5)
    end

    it 'should contain 10' do
      expect(described_class.new(:name => '65000:192.168.1.1', :allow_as_in => '10')[:allow_as_in]).to eq(10)
    end
  end

  describe 'default_originate' do
    it 'should support \'true\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => 'true') }.to_not raise_error
    end

    it 'should support :true as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => :true) }.to_not raise_error
    end

    it 'should support true as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => true) }.to_not raise_error
    end

    it 'should support \'false\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => 'false') }.to_not raise_error
    end

    it 'should support :false as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => :false) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => false) }.to_not raise_error
    end

    it 'should support \'enabled\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => 'enabled') }.to_not raise_error
    end

    it 'should support :enabled as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => :enabled) }.to_not raise_error
    end

    it 'should support \'disabled\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => 'disabled') }.to_not raise_error
    end

    it 'should support :disabled as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => :disabled) }.to_not raise_error
    end

    it 'should not support allow as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :default_originate => 'allow') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain enabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :default_originate => 'true')[:default_originate]).to eq(:enabled)
    end

    it 'should contain enabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :default_originate => 'enabled')[:default_originate]).to eq(:enabled)
    end

    it 'should contain enabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :default_originate => true)[:default_originate]).to eq(:enabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :default_originate => 'false')[:default_originate]).to eq(:disabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :default_originate => 'disabled')[:default_originate]).to eq(:disabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :default_originate => :disabled)[:default_originate]).to eq(:disabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :default_originate => false)[:default_originate]).to eq(:disabled)
    end
  end

  describe 'next_hop_self' do
    it 'should support \'true\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => 'true') }.to_not raise_error
    end

    it 'should support :true as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => :true) }.to_not raise_error
    end

    it 'should support true as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => true) }.to_not raise_error
    end

    it 'should support \'false\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => 'false') }.to_not raise_error
    end

    it 'should support :false as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => :false) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => false) }.to_not raise_error
    end

    it 'should support \'enabled\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => 'enabled') }.to_not raise_error
    end

    it 'should support :enabled as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => :enabled) }.to_not raise_error
    end

    it 'should support \'disabled\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => 'disabled') }.to_not raise_error
    end

    it 'should support :disabled as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => :disabled) }.to_not raise_error
    end

    it 'should not support allow as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :next_hop_self => 'allow') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain enabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :next_hop_self => 'true')[:next_hop_self]).to eq(:enabled)
    end

    it 'should contain enabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :next_hop_self => 'enabled')[:next_hop_self]).to eq(:enabled)
    end

    it 'should contain enabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :next_hop_self => true)[:next_hop_self]).to eq(:enabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :next_hop_self => 'false')[:next_hop_self]).to eq(:disabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :next_hop_self => 'disabled')[:next_hop_self]).to eq(:disabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :next_hop_self => :disabled)[:next_hop_self]).to eq(:disabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :next_hop_self => false)[:next_hop_self]).to eq(:disabled)
    end
  end

  describe 'peer_group' do
    it 'should support \'true\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => 'true') }.to_not raise_error
    end

    it 'should support :true as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => :true) }.to_not raise_error
    end

    it 'should support true as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => true) }.to_not raise_error
    end

    it 'should support \'false\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => 'false') }.to_not raise_error
    end

    it 'should support :false as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => :false) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => false) }.to_not raise_error
    end

    it 'should support \'enabled\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => 'enabled') }.to_not raise_error
    end

    it 'should support :enabled as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => :enabled) }.to_not raise_error
    end

    it 'should support \'disabled\' as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => 'disabled') }.to_not raise_error
    end

    it 'should support :disabled as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => :disabled) }.to_not raise_error
    end

    it 'should support peer_group as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => 'peer_group') }.to_not raise_error
    end

    it 'should support peer_group_1 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => :peer_group_1) }.to_not raise_error
    end

    it 'should not support 9-allow as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :peer_group => '9-allow') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain enabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :peer_group => 'true')[:peer_group]).to eq(:enabled)
    end

    it 'should contain enabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :peer_group => 'enabled')[:peer_group]).to eq(:enabled)
    end

    it 'should contain enabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :peer_group => true)[:peer_group]).to eq(:enabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :peer_group => 'false')[:peer_group]).to eq(:disabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :peer_group => 'disabled')[:peer_group]).to eq(:disabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :peer_group => :disabled)[:peer_group]).to eq(:disabled)
    end

    it 'should contain disabled' do
      expect(described_class.new(:name => '65000:192.168.1.1', :peer_group => false)[:peer_group]).to eq(:disabled)
    end

    it 'should contain peer_group' do
      expect(described_class.new(:name => '65000:192.168.1.1', :peer_group => 'peer_group')[:peer_group]).to eq(:peer_group)
    end

    it 'should contain peer_group_1' do
      expect(described_class.new(:name => '65000:192.168.1.1', :peer_group => 'peer_group_1')[:peer_group]).to eq(:peer_group_1)
    end
  end

  describe 'local_as' do
    it 'should support 100 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :local_as => '100') }.to_not raise_error
    end

    it 'should support 100 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :local_as => 100) }.to_not raise_error
    end

    it 'should not support 0 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :local_as => 0) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support AS100 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :local_as => 'AS100') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain 100' do
      expect(described_class.new(:name => '65000:192.168.1.1', :local_as => '100')[:local_as]).to eq(100)
    end

    it 'should contain 100' do
      expect(described_class.new(:name => '65000:192.168.1.1', :local_as => 100)[:local_as]).to eq(100)
    end
  end

  describe 'remote_as' do
    it 'should support 100 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :remote_as => '100') }.to_not raise_error
    end

    it 'should support 100 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :remote_as => 100) }.to_not raise_error
    end

    it 'should not support 0 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :remote_as => 0) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support AS100 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :remote_as => 'AS100') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain 100' do
      expect(described_class.new(:name => '65000:192.168.1.1', :remote_as => '100')[:remote_as]).to eq(100)
    end

    it 'should contain 100' do
      expect(described_class.new(:name => '65000:192.168.1.1', :remote_as => 100)[:remote_as]).to eq(100)
    end
  end

  describe 'prefix_list_in' do
    it 'should support AS100_in as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :prefix_list_in => 'AS100_in') }.to_not raise_error
    end

    it 'should support AS100-in as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :prefix_list_in => 'AS100-in') }.to_not raise_error
    end

    it 'should not support 9AS as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :prefix_list_in => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 911 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :prefix_list_in => '911') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain AS100-in' do
      expect(described_class.new(:name => '65000:192.168.1.1', :prefix_list_in => 'AS100-in')[:prefix_list_in]).to eq('AS100-in')
    end

    it 'should contain AS100_in' do
      expect(described_class.new(:name => '65000:192.168.1.1', :prefix_list_in => 'AS100_in')[:prefix_list_in]).to eq('AS100_in')
    end
  end

  describe 'prefix_list_out' do
    it 'should support AS100_out as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :prefix_list_out => 'AS100_out') }.to_not raise_error
    end

    it 'should support AS100-out as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :prefix_list_out => 'AS100-out') }.to_not raise_error
    end

    it 'should not support 9AS as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :prefix_list_out => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 911 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :prefix_list_out => '911') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain AS100-out' do
      expect(described_class.new(:name => '65000:192.168.1.1', :prefix_list_out => 'AS100-out')[:prefix_list_out]).to eq('AS100-out')
    end

    it 'should contain AS100_out' do
      expect(described_class.new(:name => '65000:192.168.1.1', :prefix_list_out => 'AS100_out')[:prefix_list_out]).to eq('AS100_out')
    end
  end

  describe 'route_map_export' do
    it 'should support AS100_export as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_export => 'AS100_export') }.to_not raise_error
    end

    it 'should support AS100-export as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_export => 'AS100-export') }.to_not raise_error
    end

    it 'should not support 9AS as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_export => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 911 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_export => '911') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain AS100-export' do
      expect(described_class.new(:name => '65000:192.168.1.1', :route_map_export => 'AS100-export')[:route_map_export]).to eq('AS100-export')
    end

    it 'should contain AS100_export' do
      expect(described_class.new(:name => '65000:192.168.1.1', :route_map_export => 'AS100_export')[:route_map_export]).to eq('AS100_export')
    end
  end

  describe 'route_map_import' do
    it 'should support AS100_import as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_import => 'AS100_import') }.to_not raise_error
    end

    it 'should support AS100-import as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_import => 'AS100-import') }.to_not raise_error
    end

    it 'should not support 9AS as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_import => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 911 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_import => '911') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain AS100-import' do
      expect(described_class.new(:name => '65000:192.168.1.1', :route_map_import => 'AS100-import')[:route_map_import]).to eq('AS100-import')
    end

    it 'should contain AS100_import' do
      expect(described_class.new(:name => '65000:192.168.1.1', :route_map_import => 'AS100_import')[:route_map_import]).to eq('AS100_import')
    end
  end

  describe 'route_map_in' do
    it 'should support AS100_in as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_in => 'AS100_in') }.to_not raise_error
    end

    it 'should support AS100-in as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_in => 'AS100-in') }.to_not raise_error
    end

    it 'should not support 9AS as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_in => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 911 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_in => '911') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain AS100-in' do
      expect(described_class.new(:name => '65000:192.168.1.1', :route_map_in => 'AS100-in')[:route_map_in]).to eq('AS100-in')
    end

    it 'should contain AS100_in' do
      expect(described_class.new(:name => '65000:192.168.1.1', :route_map_in => 'AS100_in')[:route_map_in]).to eq('AS100_in')
    end
  end

  describe 'route_map_out' do
    it 'should support AS100_out as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_out => 'AS100_out') }.to_not raise_error
    end

    it 'should support AS100-out as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_out => 'AS100-out') }.to_not raise_error
    end

    it 'should not support 9AS as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_out => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 911 as a value' do
      expect { described_class.new(:name => '65000:192.168.1.1', :route_map_out => '911') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain AS100-out' do
      expect(described_class.new(:name => '65000:192.168.1.1', :route_map_out => 'AS100-out')[:route_map_out]).to eq('AS100-out')
    end

    it 'should contain AS100_out' do
      expect(described_class.new(:name => '65000:192.168.1.1', :route_map_out => 'AS100_out')[:route_map_out]).to eq('AS100_out')
    end
  end
end