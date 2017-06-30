require 'spec_helper'

describe Puppet::Type.type(:quagga_bgp_community_list) do
  let(:provider) do
    @provider_class = describe_class.provide(:quagga_bgp_community_list) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:quagga_bgp_community_list)
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

    [ :rules ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => '100', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => '100', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => '100', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'name' do
    it 'should support as100 as a value' do
      expect { described_class.new(:name => '100') }.to_not raise_error
    end

    it 'should support as100 as a value' do
      expect { described_class.new(:name => '100') }.to_not raise_error
    end

    it 'should not support as100 as a value' do
      expect { described_class.new(:name => 'as100') }.to raise_error(Puppet::Error, /Community list number: 1-500/)
    end
  end

  describe 'rules' do
    it 'should support \'premit 65000:1\' as a value' do
      expect { described_class.new(:name => '100', :rules => 'permit 65000:1') }.to_not raise_error
    end

    it 'should support [\'permit 65000:1\', \'permit 65000:2\'] as a value' do
      expect { described_class.new(:name => '100', :rules => ['permit 65000:1', 'permit 65000:2']) }.to_not raise_error
    end

    it 'should not support [\'permit AS65000:1\', \'permit => 65000:2\'] as a value' do
      expect { described_class.new(:name => '100', :rules => ['permit AS65000:1', 'permit 65000:2']) }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support [\'reject 65000:1\', \'permit 65000:2\'] as a value' do
      expect { described_class.new(:name => '100', :rules => ['reject 65000:1', 'permit 65000:2']) }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain [\'permit 65000:1\']' do
      expect(described_class.new(:name => '100', :rules => 'permit 65000:1')[:rules]).to eq(['permit 65000:1'])
    end

    it 'should contain [\'permit 65000:1\', \'permit 65000:2\']' do
      expect(described_class.new(:name => '100', :rules => ['permit 65000:1', 'permit 65000:2'])[:rules]).to eq(['permit 65000:1', 'permit 65000:2'])
    end
  end
end