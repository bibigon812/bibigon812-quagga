require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_peer) do
  let(:quagga_bgp_peer) do
    @provider_class = describe_class.provide(:quagga_bgp_peer) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
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

  # describe 'allow_as_in' do
  #   it 'should support \'1\' as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :allow_as_in => '1') }.to_not raise_error
  #   end
  #
  #   it 'should support 1 as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :allow_as_in => 1) }.to_not raise_error
  #   end
  #
  #   it 'should not support 0 as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :allow_as_in => 0) }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should not support -1 as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :allow_as_in => -1) }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should not support \'a lot\' as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :allow_as_in => 'a lot') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should contain 1' do
  #     expect(described_class.new(:name => '192.168.1.1', :allow_as_in => '1')[:allow_as_in]).to eq(1)
  #   end
  #
  #   it 'should contain 2' do
  #     expect(described_class.new(:name => '192.168.1.1', :allow_as_in => 2)[:allow_as_in]).to eq(2)
  #   end
  #
  #   it 'should contain 5' do
  #     expect(described_class.new(:name => '192.168.1.1', :allow_as_in => 5)[:allow_as_in]).to eq(5)
  #   end
  #
  #   it 'should contain 10' do
  #     expect(described_class.new(:name => '192.168.1.1', :allow_as_in => '10')[:allow_as_in]).to eq(10)
  #   end
  # end

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
      expect { described_class.new(:name => '192.168.1.1', property => '100') }.to_not raise_error
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
      expect(described_class.new(:name => '192.168.1.1', property => '100')[property]).to eq(100)
    end

    it 'should contain 100' do
      expect(described_class.new(:name => '192.168.1.1', property => 100)[property]).to eq(100)
    end
    end
  end

  # describe 'prefix_list_in' do
  #   it 'should support AS100_in as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :prefix_list_in => 'AS100_in') }.to_not raise_error
  #   end
  #
  #   it 'should support AS100-in as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :prefix_list_in => 'AS100-in') }.to_not raise_error
  #   end
  #
  #   it 'should not support 9AS as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :prefix_list_in => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should not support 911 as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :prefix_list_in => '911') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should contain AS100-in' do
  #     expect(described_class.new(:name => '192.168.1.1', :prefix_list_in => 'AS100-in')[:prefix_list_in]).to eq('AS100-in')
  #   end
  #
  #   it 'should contain AS100_in' do
  #     expect(described_class.new(:name => '192.168.1.1', :prefix_list_in => 'AS100_in')[:prefix_list_in]).to eq('AS100_in')
  #   end
  # end
  #
  # describe 'prefix_list_out' do
  #   it 'should support AS100_out as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :prefix_list_out => 'AS100_out') }.to_not raise_error
  #   end
  #
  #   it 'should support AS100-out as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :prefix_list_out => 'AS100-out') }.to_not raise_error
  #   end
  #
  #   it 'should not support 9AS as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :prefix_list_out => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should not support 911 as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :prefix_list_out => '911') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should contain AS100-out' do
  #     expect(described_class.new(:name => '192.168.1.1', :prefix_list_out => 'AS100-out')[:prefix_list_out]).to eq('AS100-out')
  #   end
  #
  #   it 'should contain AS100_out' do
  #     expect(described_class.new(:name => '192.168.1.1', :prefix_list_out => 'AS100_out')[:prefix_list_out]).to eq('AS100_out')
  #   end
  # end
  #
  # describe 'route_map_export' do
  #   it 'should support AS100_export as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_export => 'AS100_export') }.to_not raise_error
  #   end
  #
  #   it 'should support AS100-export as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_export => 'AS100-export') }.to_not raise_error
  #   end
  #
  #   it 'should not support 9AS as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_export => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should not support 911 as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_export => '911') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should contain AS100-export' do
  #     expect(described_class.new(:name => '192.168.1.1', :route_map_export => 'AS100-export')[:route_map_export]).to eq('AS100-export')
  #   end
  #
  #   it 'should contain AS100_export' do
  #     expect(described_class.new(:name => '192.168.1.1', :route_map_export => 'AS100_export')[:route_map_export]).to eq('AS100_export')
  #   end
  # end
  #
  # describe 'route_map_import' do
  #   it 'should support AS100_import as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_import => 'AS100_import') }.to_not raise_error
  #   end
  #
  #   it 'should support AS100-import as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_import => 'AS100-import') }.to_not raise_error
  #   end
  #
  #   it 'should not support 9AS as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_import => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should not support 911 as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_import => '911') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should contain AS100-import' do
  #     expect(described_class.new(:name => '192.168.1.1', :route_map_import => 'AS100-import')[:route_map_import]).to eq('AS100-import')
  #   end
  #
  #   it 'should contain AS100_import' do
  #     expect(described_class.new(:name => '192.168.1.1', :route_map_import => 'AS100_import')[:route_map_import]).to eq('AS100_import')
  #   end
  # end
  #
  # describe 'route_map_in' do
  #   it 'should support AS100_in as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_in => 'AS100_in') }.to_not raise_error
  #   end
  #
  #   it 'should support AS100-in as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_in => 'AS100-in') }.to_not raise_error
  #   end
  #
  #   it 'should not support 9AS as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_in => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should not support 911 as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_in => '911') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should contain AS100-in' do
  #     expect(described_class.new(:name => '192.168.1.1', :route_map_in => 'AS100-in')[:route_map_in]).to eq('AS100-in')
  #   end
  #
  #   it 'should contain AS100_in' do
  #     expect(described_class.new(:name => '192.168.1.1', :route_map_in => 'AS100_in')[:route_map_in]).to eq('AS100_in')
  #   end
  # end

  # describe 'route_map_out' do
  #   it 'should support AS100_out as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_out => 'AS100_out') }.to_not raise_error
  #   end
  #
  #   it 'should support AS100-out as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_out => 'AS100-out') }.to_not raise_error
  #   end
  #
  #   it 'should not support 9AS as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_out => '9AS') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should not support 911 as a value' do
  #     expect { described_class.new(:name => '192.168.1.1', :route_map_out => '911') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should contain AS100-out' do
  #     expect(described_class.new(:name => '192.168.1.1', :route_map_out => 'AS100-out')[:route_map_out]).to eq('AS100-out')
  #   end
  #
  #   it 'should contain AS100_out' do
  #     expect(described_class.new(:name => '192.168.1.1', :route_map_out => 'AS100_out')[:route_map_out]).to eq('AS100_out')
  #   end
  # end

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
end