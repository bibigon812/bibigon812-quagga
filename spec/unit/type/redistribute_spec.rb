require 'spec_helper'

describe Puppet::Type.type(:redistribute) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:redistribute) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:redistribute)
  end

  it 'should have :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe "when validating attributes" do
    [ :name, :provider ].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [ :metric, :metric_type, :route_map ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'ospf::connected', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'bgp:65000:ospf', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'ospf::static', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'name' do
    it 'should support \'ospf::kernel\'' do
      expect { described_class.new(:name => 'ospf::kernel') }.to_not raise_error
    end

    it 'should not support \'ospf::ospf\'' do
      expect { described_class.new(:name => 'ospf::ospf') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support \'bgp:65000:isis\'s' do
      expect { described_class.new(:name => 'bgp:65000:isis') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  describe 'metric' do
    it 'should support 100 as a value' do
      expect { described_class.new(:name => 'ospf::connected', :metric => 100) }.to_not raise_error
    end

    it 'should support 100000 as a value' do
      expect { described_class.new(:name => 'ospf::connected', :metric => 100000) }.to_not raise_error
    end

    it 'should support \'100\' as a value' do
      expect { described_class.new(:name => 'ospf::connected', :metric => '100') }.to_not raise_error
    end

    it 'should not support -1 as a value' do
      expect { described_class.new(:name => 'ospf::connected', :metric => -1) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain 100' do
      expect(described_class.new(:name => 'ospf::connected', :metric => 100)[:metric]).to eq(100)
    end

    it 'should contain 200' do
      expect(described_class.new(:name => 'ospf::connected', :metric => '200')[:metric]).to eq(200)
    end
  end
end
