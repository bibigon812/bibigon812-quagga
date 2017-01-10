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

    [:abr_type, :default_information, :network, :redistribute, :router_id,
    ].each do |property|
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

  describe 'default_information' do
    it 'should support orignate as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => :originate) }.to_not raise_error
    end

    it 'should support  as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'originate always') }.to_not raise_error
    end

    it 'should not support \'{originate => }\' as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => '{originate => }') }.to raise_error(Puppet::Error, /is not a Hash/)
    end

    it 'should contain { originate => always }' do
      expect(described_class.new(:name => 'ospf', :default_information => 'originate always')[:default_information]).to eq(:ibm)
    end
    #
    # it 'should contain standard' do
    #   expect(described_class.new(:name => 'ospf', :default_information => 'standard')[:default_information]).to eq(:standard)
    # end
  end
end
