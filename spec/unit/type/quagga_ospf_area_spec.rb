require 'spec_helper'

describe Puppet::Type.type(:quagga_ospf_area) do
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

  let(:router) { Puppet::Type.type(:quagga_ospf_router).new(:name => 'ospf') }
  let(:catalog) { Puppet::Resource::Catalog.new }

  before :each do
    Puppet::Type.type(:quagga_ospf_area).stubs(:defaultprovider).returns providerclass
  end

  after :each do
    described_class.unprovide(:quagga_ospf_area)
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

    [:access_list_export, :access_list_import, :prefix_list_export,
      :prefix_list_import, :networks ].each do |property|
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

  describe 'auth' do
    it 'should support true as a value' do
      expect { described_class.new(:name => '0.0.0.0', :auth => true) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '0.0.0.0', :auth => false) }.to_not raise_error
    end

    it 'should support message-digest as a value' do
      expect { described_class.new(:name => '0.0.0.0', :auth => "message-digest") }.to_not raise_error
    end

    it 'should contain :true' do
      expect(described_class.new(name: '0.0.0.0', :auth => true)[:auth]).to eq(:true)
    end

    it 'should contain :false' do
      expect(described_class.new(name: '0.0.0.0', :auth => false)[:auth]).to eq(:false)
    end

    it 'should contain :message-digest' do
      expect(described_class.new(name: '0.0.0.0', :auth => 'message-digest')[:auth]).to eq(:"message-digest")
    end

    it 'should not support foo as a value' do
      expect { described_class.new(:name => '0.0.0.0', :auth => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  describe "stub" do
    it 'should support true as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => true) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => false) }.to_not raise_error
    end

    it 'should support no-summary as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => "no-summary") }.to_not raise_error
    end

    it 'should contain :true' do
      expect(described_class.new(name: '0.0.0.0', :stub => true)[:stub]).to eq(:true)
    end

    it 'should contain :false' do
      expect(described_class.new(name: '0.0.0.0', :stub => false)[:stub]).to eq(:false)
    end

    it 'should contain :no-summary' do
      expect(described_class.new(name: '0.0.0.0', :stub => 'no-summary')[:stub]).to eq(:"no-summary")
    end


    it 'should not support foo as a value' do
      expect { described_class.new(:name => '0.0.0.0', :stub => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  [:access_list_export, :access_list_import, :prefix_list_export, :prefix_list_import].each do |property|
    describe "#{property}" do
      it 'should support LIST-import as a value' do
        expect { described_class.new(:name => '0.0.0.0', :prefix_list_import => 'LIST-import') }.to_not raise_error
      end

      it 'should support :list_import as a value' do
        expect { described_class.new(:name => '0.0.0.0', :prefix_list_import => :list_import) }.to_not raise_error
      end

      it 'should not support @list-import as a value' do
        expect { described_class.new(:name => '0.0.0.0', :prefix_list_import => '@list-import') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support -list-import as a value' do
        expect { described_class.new(:name => '0.0.0.0', :prefix_list_import => '-list-import') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 9-list-import as a value' do
        expect { described_class.new(:name => '0.0.0.0', :prefix_list_import => '9-list-import') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should contain list-import' do
        expect(described_class.new(:name => '0.0.0.0', :prefix_list_import => 'list-import')[:prefix_list_import]).to eq('list-import')
      end
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
      expect { described_class.new(:name => '0.0.0.0', :networks => '10.256.0.0/24') }.to raise_error Puppet::Error, /Not a valid network address/
    end

    it 'should not support 10.255.0.0 as a value' do
      expect { described_class.new(:name => '0.0.0.0', :networks => '10.255.0.0') }.to raise_error Puppet::Error, /Prefix length is not specified/
    end

    it 'should contain [ \'10.255.255.0/24\' ]' do
      expect(described_class.new(:name => '0.0.0.0', :networks => '10.255.255.0/24')[:networks]).to eq(%w{10.255.255.0/24})
    end

    it 'should contain [ \'10.255.255.0/24\', \'192.168.0.0/16\' ]' do
      expect(described_class.new(:name => '0.0.0.0', :networks => %w{10.255.255.0/24 192.168.0.0/16})[:networks]).to eq(%w{10.255.255.0/24 192.168.0.0/16})
    end
  end

  describe 'when autorequiring' do
    it 'should require quagga_ospf_reoute resource' do
      area = described_class.new(:name => '0.0.0.0', :stub => true)
      catalog.add_resource router
      catalog.add_resource area
      reqs = area.autorequire

      expect(reqs.size).to eq(1)
      expect(reqs[0].source).to eq(router)
      expect(reqs[0].target).to eq(area)
    end
  end
end
