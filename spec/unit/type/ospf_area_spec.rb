require 'spec_helper'

describe Puppet::Type.type(:ospf_area) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:ospf_area) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:ospf_area)
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

    [ :default_cost, :access_list_export, :access_list_import, :prefix_list_export,
      :prefix_list_import, :networks, :shortcut ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => '0.0.0.0', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => '0.0.0.0', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => '0.0.0.0', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'default_cost' do
    it 'should support 10 as a value' do
      expect { described_class.new(:name => '0.0.0.0', :default_cost => 10) }.to_not raise_error
    end

    it 'should support 20 as a value' do
      expect { described_class.new(:name => '0.0.0.0', :default_cost => '20') }.to_not raise_error
    end

    it 'should not support -1 as a value' do
      expect { described_class.new(:name => '0.0.0.0', :default_cost => -1) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain 100' do
      expect(described_class.new(:name => '0.0.0.0', :default_cost => 100)[:default_cost]).to eq(100)
    end

    it 'should contain 200' do
      expect(described_class.new(:name => '0.0.0.0', :default_cost => '200')[:default_cost]).to eq(200)
    end
  end

  describe 'access_list_export' do
    it 'should support LIST-export as a value' do
      expect { described_class.new(:name => '0.0.0.0', :access_list_export => 'LIST-export') }.to_not raise_error
    end

    it 'should support :access_list_export as a value' do
      expect { described_class.new(:name => '0.0.0.0', :access_list_export => :access_list_export) }.to_not raise_error
    end

    it 'should not support @access_list-export as a value' do
      expect { described_class.new(:name => '0.0.0.0', :access_list_export => '@access_list-export') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support -access_list-export as a value' do
      expect { described_class.new(:name => '0.0.0.0', :access_list_export => '-access_list-export') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 9-access_list-export as a value' do
      expect { described_class.new(:name => '0.0.0.0', :access_list_export => '9-access_list-export') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain access_list_export' do
      expect(described_class.new(:name => '0.0.0.0', :access_list_export => :access_list_export)[:access_list_export]).to eq('access_list_export')
    end

    it 'should contain access_list-export' do
      expect(described_class.new(:name => '0.0.0.0', :access_list_export => 'access_list-export')[:access_list_export]).to eq('access_list-export')
    end
  end

  describe 'access_list_import' do
    it 'should support LIST-import as a value' do
      expect { described_class.new(:name => '0.0.0.0', :access_list_import => 'LIST-import') }.to_not raise_error
    end

    it 'should support :access_list_import as a value' do
      expect { described_class.new(:name => '0.0.0.0', :access_list_import => :access_list_import) }.to_not raise_error
    end

    it 'should not support @access_list-import as a value' do
      expect { described_class.new(:name => '0.0.0.0', :access_list_import => '@access_list-import') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support -access_list-import as a value' do
      expect { described_class.new(:name => '0.0.0.0', :access_list_import => '-access_list-import') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 9-access_list-import as a value' do
      expect { described_class.new(:name => '0.0.0.0', :access_list_import => '9-access_list-import') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain access_list_import' do
      expect(described_class.new(:name => '0.0.0.0', :access_list_import => :access_list_import)[:access_list_import]).to eq('access_list_import')
    end

    it 'should contain access_list-import' do
      expect(described_class.new(:name => '0.0.0.0', :access_list_import => 'access_list-import')[:access_list_import]).to eq('access_list-import')
    end
  end

  describe 'prefix_list_export' do
    it 'should support LIST-export as a value' do
      expect { described_class.new(:name => '0.0.0.0', :prefix_list_export => 'LIST-export') }.to_not raise_error
    end

    it 'should support :prefix_list_export as a value' do
      expect { described_class.new(:name => '0.0.0.0', :prefix_list_export => :prefix_list_export) }.to_not raise_error
    end

    it 'should not support @prefix_list-export as a value' do
      expect { described_class.new(:name => '0.0.0.0', :prefix_list_export => '@prefix_list-export') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support -prefix_list-export as a value' do
      expect { described_class.new(:name => '0.0.0.0', :prefix_list_export => '-prefix_list-export') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 9-prefix_list-export as a value' do
      expect { described_class.new(:name => '0.0.0.0', :prefix_list_export => '9-prefix_list-export') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain prefix_list_export' do
      expect(described_class.new(:name => '0.0.0.0', :prefix_list_export => :prefix_list_export)[:prefix_list_export]).to eq('prefix_list_export')
    end

    it 'should contain prefix_list-export' do
      expect(described_class.new(:name => '0.0.0.0', :prefix_list_export => 'prefix_list-export')[:prefix_list_export]).to eq('prefix_list-export')
    end
  end

  describe 'prefix_list_import' do
    it 'should support LIST-import as a value' do
      expect { described_class.new(:name => '0.0.0.0', :prefix_list_import => 'LIST-import') }.to_not raise_error
    end

    it 'should support :prefix_list_import as a value' do
      expect { described_class.new(:name => '0.0.0.0', :prefix_list_import => :prefix_list_import) }.to_not raise_error
    end

    it 'should not support @prefix_list-import as a value' do
      expect { described_class.new(:name => '0.0.0.0', :prefix_list_import => '@prefix_list-import') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support -prefix_list-import as a value' do
      expect { described_class.new(:name => '0.0.0.0', :prefix_list_import => '-prefix_list-import') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support 9-prefix_list-import as a value' do
      expect { described_class.new(:name => '0.0.0.0', :prefix_list_import => '9-prefix_list-import') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain prefix_list_import' do
      expect(described_class.new(:name => '0.0.0.0', :prefix_list_import => :prefix_list_import)[:prefix_list_import]).to eq('prefix_list_import')
    end

    it 'should contain prefix_list-import' do
      expect(described_class.new(:name => '0.0.0.0', :prefix_list_import => 'prefix_list-import')[:prefix_list_import]).to eq('prefix_list-import')
    end
  end

  describe 'networks' do
    it 'should support 10.0.0.0/24 as a value' do
      expect { described_class.new(:name => '0.0.0.0', :networks => '10.0.0.0/24') }.to_not raise_error
    end

    it 'should support 10.255.255.0/24 as a value' do
      expect { described_class.new(:name => '0.0.0.0', :networks => %w{10.255.255.0/24 192.168.0.0/16}) }.to_not raise_error
    end

    it 'should not support 10.256.0.0/24 as a value' do
      expect { described_class.new(:name => '0.0.0.0', :networks => '10.256.0.0/24') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain [ \'10.255.255.0/24\' ]' do
      expect(described_class.new(:name => '0.0.0.0', :networks => '10.255.255.0/24')[:networks]).to eq(%w{10.255.255.0/24})
    end

    it 'should contain [ \'10.255.255.0/24\', \'192.168.0.0/16\' ]' do
      expect(described_class.new(:name => '0.0.0.0', :networks => %w{10.255.255.0/24 192.168.0.0/16})[:networks]).to eq(%w{10.255.255.0/24 192.168.0.0/16})
    end
  end

  describe 'shortcut' do
    it 'should support true as a value' do
      expect { described_class.new(:name => '0.0.0.0', :shortcut => true) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '0.0.0.0', :shortcut => 'false') }.to_not raise_error
    end

    it 'should support true as a value' do
      expect { described_class.new(:name => '0.0.0.0', :shortcut => :enable) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '0.0.0.0', :shortcut => 'disable') }.to_not raise_error
    end

    it 'should support default as a value' do
      expect { described_class.new(:name => '0.0.0.0', :shortcut => :default) }.to_not raise_error
    end

    it 'should not support vasya as a value' do
      expect { described_class.new(:name => '0.0.0.0', :shortcut => :vasya) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain enable' do
      expect(described_class.new(:name => '0.0.0.0', :shortcut => :true)[:shortcut]).to eq(:enable)
    end

    it 'should contain enable' do
      expect(described_class.new(:name => '0.0.0.0', :shortcut => :enable)[:shortcut]).to eq(:enable)
    end

    it 'should contain disable' do
      expect(described_class.new(:name => '0.0.0.0', :shortcut => 'disable')[:shortcut]).to eq(:disable)
    end

    it 'should contain disable' do
      expect(described_class.new(:name => '0.0.0.0', :shortcut => :false)[:shortcut]).to eq(:disable)
    end

    it 'should contain default' do
      expect(described_class.new(:name => '0.0.0.0', :shortcut => 'default')[:shortcut]).to eq(:default)
    end
  end

  describe 'stub' do
    it 'should support true as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => true) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => 'false') }.to_not raise_error
    end

    it 'should support no_summary as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => :no_summary) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => 'disable') }.to_not raise_error
    end

    it 'should support no_summary as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => :enable) }.to_not raise_error
    end

    it 'should support no_summary as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => 'no-summary') }.to_not raise_error
    end

    it 'should support no_summary as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => 'no_summary') }.to_not raise_error
    end

    it 'should not support vasya as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => :vasya) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support petya as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => 'petya') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain true' do
      expect(described_class.new(:name => '0.0.0.0', :stub => :true)[:stub]).to eq(:enable)
    end

    it 'should contain true' do
      expect(described_class.new(:name => '0.0.0.0', :stub => true)[:stub]).to eq(:enable)
    end


    it 'should contain false' do
      expect(described_class.new(:name => '0.0.0.0', :stub => 'false')[:stub]).to eq(:disable)
    end

    it 'should contain no-summary' do
      expect(described_class.new(:name => '0.0.0.0', :stub => :no_summary)[:stub]).to eq(:no_summary)
    end

    it 'should contain no-summary' do
      expect(described_class.new(:name => '0.0.0.0', :stub => 'no-summary')[:stub]).to eq(:no_summary)
    end
  end
end
