require 'spec_helper'

describe Puppet::Type.type(:pim_interface) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:pim_interface) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:pim_interface)
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

    [:igmp, :pim_ssm, :igmp_query_interval, :igmp_query_max_response_time_dsec].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'foo', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'foo', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'foo', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'igmp' do
      it 'should support true as a value' do
        expect { described_class.new(:name => 'foo', :igmp => true) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(:name => 'foo', :igmp => false) }.to_not raise_error
      end

      it 'should not support foo as a value' do
        expect { described_class.new(:name => 'foo', :igmp => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'pim_ssm' do
      it 'should support true as a value' do
        expect { described_class.new(:name => 'foo', :pim_ssm => true) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(:name => 'foo', :pim_ssm => false) }.to_not raise_error
      end

      it 'should not support foo as a value' do
        expect { described_class.new(:name => 'foo', :pim_ssm => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'igmp_query_interval' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :igmp_query_interval => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :igmp_query_interval => 0) }.to raise_error(Puppet::Error, /between 1-1800/)
      end

      it 'should not support 1801 as a value' do
        expect { described_class.new(:name => 'foo', :igmp_query_interval => 1801) }.to raise_error(Puppet::Error, /between 1-1800/)
      end

      it 'should not support \'50\' as a value' do
        expect { described_class.new(:name => 'foo', :igmp_query_interval => '50') }.to raise_error(Puppet::Error, /is not an Integer/)
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :igmp_query_interval => 50)[:igmp_query_interval]).to eq(50)
      end
    end

    describe 'igmp_query_max_response_time_dsec' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :igmp_query_max_response_time_dsec => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :igmp_query_max_response_time_dsec => 0) }.to raise_error(Puppet::Error, /between 10-250/)
      end

      it 'should not support 251 as a value' do
        expect { described_class.new(:name => 'foo', :igmp_query_max_response_time_dsec => 251) }.to raise_error(Puppet::Error, /between 10-250/)
      end

      it 'should not support \'50\' as a value' do
        expect { described_class.new(:name => 'foo', :igmp_query_max_response_time_dsec => '50') }.to raise_error(Puppet::Error, /is not an Integer/)
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :igmp_query_max_response_time_dsec => 50)[:igmp_query_max_response_time_dsec]).to eq(50)
      end
    end
  end
end
