require 'spec_helper'

describe Puppet::Type.type(:ospf) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:ospf) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:ospf)
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

    [:abr_type, :opaque, :rfc1583, :router_id, :log_adjacency_changes].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'name' do
    it 'should support ospf as a value' do
      expect { described_class.new(:name => 'ospf') }.to_not raise_error
    end

    it 'should not support foo as a value' do
      expect { described_class.new(:name => 'foo') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'ospf', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'ospf', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'ospf', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'abr_type' do
    it 'should support cisco as a value' do
      expect { described_class.new(:name => 'ospf', :abr_type => :cisco) }.to_not raise_error
    end

    it 'should support shortcut as a value' do
      expect { described_class.new(:name => 'ospf', :abr_type => :shortcut) }.to_not raise_error
    end

    it 'should not support juniper as a value' do
      expect { described_class.new(:name => 'ospf', :abr_type => :juniper) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain ibm' do
      expect(described_class.new(:name => 'ospf', :abr_type => :ibm)[:abr_type]).to eq(:ibm)
    end

    it 'should contain standard' do
      expect(described_class.new(:name => 'ospf', :abr_type => :standard)[:abr_type]).to eq(:standard)
    end
  end

  [:opaque, :rfc1583].each do |property|
    describe "boolean values of the property `#{property}`" do
      it 'should support true as a value' do
        expect { described_class.new(:name => 'ospf', property => true) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(:name => 'ospf', property => false) }.to_not raise_error
      end

      it 'should contain :true' do
        expect(described_class.new(:name => 'ospf', property => true)[property]).to eq(:true)
      end

      it 'should contain :false' do
        expect(described_class.new(:name => 'ospf', property => false)[property]).to eq(:false)
      end

      it 'should not support foo as a value' do
        expect { described_class.new(:name => 'ospf', property => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'router_id' do
    it 'should support \'1.1.1.1\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '1.1.1.1') }.to_not raise_error
    end

    it 'should support \'0.0.0.0\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '0.0.0.0') }.to_not raise_error
    end

    it 'should support \'255.255.255.255\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '255.255.255.255') }.to_not raise_error
    end

    it 'should not support \'1.1000.1.1\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '1.1000.1.1') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support \'1.100.256.1\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '1.100.256.1') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain \'1.1.1.1\'' do
      expect(described_class.new(:name => 'ospf', :router_id => '1.1.1.1')[:router_id]).to eq('1.1.1.1')
    end
  end

  describe 'log_adjacency_changes' do
    it 'should support true as a value' do
      expect { described_class.new(:name => 'ospf', :log_adjacency_changes => true) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => 'ospf', :log_adjacency_changes => false) }.to_not raise_error
    end

    it 'should support detail as a value' do
      expect { described_class.new(:name => 'ospf', :log_adjacency_changes => :detail) }.to_not raise_error
    end

    it 'should contain :true' do
      expect(described_class.new(:name => 'ospf', :log_adjacency_changes => true)[:log_adjacency_changes]).to eq(:true)
    end

    it 'should contain :false' do
      expect(described_class.new(:name => 'ospf', :log_adjacency_changes => false)[:log_adjacency_changes]).to eq(:false)
    end

    it 'should contain :detail' do
      expect(described_class.new(:name => 'ospf', :log_adjacency_changes => :detail)[:log_adjacency_changes]).to eq(:detail)
    end

    it 'should not support foo as a value' do
      expect { described_class.new(:name => 'ospf', :log_adjacency_changes => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end
end
