require 'spec_helper'

describe Puppet::Type.type(:quagga_ospf_area) do
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

  let(:router) { Puppet::Type.type(:quagga_ospf_router).new(name: 'ospf') }
  let(:catalog) { Puppet::Resource::Catalog.new }

  before :each do
    allow(Puppet::Type.type(:quagga_ospf_area)).to receive(:defaultprovider).and_return(providerclass)
  end

  after :each do
    described_class.unprovide(:quagga_ospf_area)
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

    [:access_list_export, :access_list_import, :prefix_list_export,
     :prefix_list_import, :networks ].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'supports present as a value' do
        expect { described_class.new(name: '0.0.0.0', ensure: :present) }.not_to raise_error
      end

      it 'supports absent as a value' do
        expect { described_class.new(name: '0.0.0.0', ensure: :absent) }.not_to raise_error
      end

      it 'does not support other values' do
        expect { described_class.new(name: '0.0.0.0', ensure: :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end
  end

  describe 'auth' do
    it 'supports true as a value' do
      expect { described_class.new(name: '0.0.0.0', auth: true) }.not_to raise_error
    end

    it 'supports false as a value' do
      expect { described_class.new(name: '0.0.0.0', auth: false) }.not_to raise_error
    end

    it 'supports message-digest as a value' do
      expect { described_class.new(name: '0.0.0.0', auth: 'message-digest') }.not_to raise_error
    end

    it 'contains :true' do
      expect(described_class.new(name: '0.0.0.0', auth: true)[:auth]).to eq(:true)
    end

    it 'contains :false' do
      expect(described_class.new(name: '0.0.0.0', auth: false)[:auth]).to eq(:false)
    end

    it 'contains :message-digest' do
      expect(described_class.new(name: '0.0.0.0', auth: 'message-digest')[:auth]).to eq(:"message-digest")
    end

    it 'does not support foo as a value' do
      expect { described_class.new(name: '0.0.0.0', auth: :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
    end
  end

  describe 'stub' do
    it 'supports true as a value' do
      expect { described_class.new(name: '0.0.0.0', stub: true) }.not_to raise_error
    end

    it 'supports false as a value' do
      expect { described_class.new(name: '0.0.0.0', stub: false) }.not_to raise_error
    end

    it 'supports no-summary as a value' do
      expect { described_class.new(name: '0.0.0.0', stub: 'no-summary') }.not_to raise_error
    end

    it 'contains :true' do
      expect(described_class.new(name: '0.0.0.0', stub: true)[:stub]).to eq(:true)
    end

    it 'contains :false' do
      expect(described_class.new(name: '0.0.0.0', stub: false)[:stub]).to eq(:false)
    end

    it 'contains :no-summary' do
      expect(described_class.new(name: '0.0.0.0', stub: 'no-summary')[:stub]).to eq(:"no-summary")
    end

    it 'does not support foo as a value' do
      expect { described_class.new(name: '0.0.0.0', stub: :foo) }.to raise_error(Puppet::Error, %r{Invalid value})
    end
  end

  [:access_list_export, :access_list_import, :prefix_list_export, :prefix_list_import].each do |property|
    describe property.to_s do
      it 'supports LIST-import as a value' do
        expect { described_class.new(name: '0.0.0.0', prefix_list_import: 'LIST-import') }.not_to raise_error
      end

      it 'supports :list_import as a value' do
        expect { described_class.new(name: '0.0.0.0', prefix_list_import: :list_import) }.not_to raise_error
      end

      it 'does not support @list-import as a value' do
        expect { described_class.new(name: '0.0.0.0', prefix_list_import: '@list-import') }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'does not support -list-import as a value' do
        expect { described_class.new(name: '0.0.0.0', prefix_list_import: '-list-import') }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'does not support 9-list-import as a value' do
        expect { described_class.new(name: '0.0.0.0', prefix_list_import: '9-list-import') }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'contains list-import' do
        expect(described_class.new(name: '0.0.0.0', prefix_list_import: 'list-import')[:prefix_list_import]).to eq('list-import')
      end
    end
  end

  describe 'networks' do
    it 'supports 10.0.0.0/24 as a value' do
      expect { described_class.new(name: '0.0.0.0', networks: '10.0.0.0/24') }.not_to raise_error
    end

    it 'supports 10.255.255.0/24 as a value' do
      expect { described_class.new(name: '0.0.0.0', networks: ['10.255.255.0/24', '192.168.0.0/16']) }.not_to raise_error
    end

    it 'does not support 10.256.0.0/24 as a value' do
      expect { described_class.new(name: '0.0.0.0', networks: '10.256.0.0/24') }.to raise_error Puppet::Error, %r{Not a valid network address}
    end

    it 'does not support 10.255.0.0 as a value' do
      expect { described_class.new(name: '0.0.0.0', networks: '10.255.0.0') }.to raise_error Puppet::Error, %r{Prefix length is not specified}
    end

    it 'contains [ \'10.255.255.0/24\' ]' do
      expect(described_class.new(name: '0.0.0.0', networks: '10.255.255.0/24')[:networks]).to eq(['10.255.255.0/24'])
    end

    it 'contains [ \'10.255.255.0/24\', \'192.168.0.0/16\' ]' do
      expect(described_class.new(name: '0.0.0.0', networks: ['10.255.255.0/24', '192.168.0.0/16'])[:networks]).to eq(['10.255.255.0/24', '192.168.0.0/16'])
    end
  end

  describe 'when autorequiring' do
    it 'requires quagga_ospf_reoute resource' do
      area = described_class.new(name: '0.0.0.0', stub: true)
      catalog.add_resource router
      catalog.add_resource area
      reqs = area.autorequire

      expect(reqs.size).to eq(1)
      expect(reqs[0].source).to eq(router)
      expect(reqs[0].target).to eq(area)
    end
  end
end
