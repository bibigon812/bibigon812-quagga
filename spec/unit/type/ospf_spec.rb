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

    [:abr_type, :opaque, :rfc1583, :router_id, ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
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
      expect(described_class.new(:name => 'ospf', :abr_type => 'standard')[:abr_type]).to eq(:standard)
    end
  end

  describe 'opaque' do
    it 'should support true as a value' do
      expect { described_class.new(:name => 'ospf', :opaque => true) }.to_not raise_error
    end

    it 'should support false as a value' do
      expect { described_class.new(:name => 'ospf', :opaque => false) }.to_not raise_error
    end

    it 'should support \'true\' as a value' do
      expect { described_class.new(:name => 'ospf', :opaque => 'true') }.to_not raise_error
    end

    it 'should support \'false\' as a value' do
      expect { described_class.new(:name => 'ospf', :opaque => 'false') }.to_not raise_error
    end

    it 'should support \'tru\' as a value' do
      expect { described_class.new(:name => 'ospf', :opaque => 'tru') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain true' do
      expect(described_class.new(:name => 'ospf', :opaque => 'true')[:opaque]).to eq(:enabled)
    end

    it 'should contain false' do
      expect(described_class.new(:name => 'ospf', :opaque => 'false')[:opaque]).to eq(:disabled)
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
end
