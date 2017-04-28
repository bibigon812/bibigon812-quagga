require 'spec_helper'

describe Puppet::Type.type(:as_path) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:as_path) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:as_path)
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
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'as100', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'as100', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'as100', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'name' do
    it 'should support as100 as a value' do
      expect { described_class.new(:name => 'as100') }.to_not raise_error
    end

    it 'should support as100 as a value' do
      expect { described_class.new(:name => 'as100') }.to_not raise_error
    end

    it 'should not support as100 as a value' do
      expect { described_class.new(:name => 'as100:1') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  describe 'rules' do
    it 'should support :premit => \'_100$\' as a value' do
      expect { described_class.new(:name => 'as100', :rules => { :permit => '_100$' }) }.to_not raise_error
    end

    it 'should support [{:permit => \'_100$\'}, {:permit => \'_100_\'}] as a value' do
      expect { described_class.new(:name => 'as100', :rules => [{:permit => '_100$'}, {:permit => '_100_'}]) }.to_not raise_error
    end

    it 'should not support [{:permit => \'_10X$\'}, {:permit => \'_100_\'}] as a value' do
      expect { described_class.new(:name => 'as100', :rules => [{:permit => '_10X$'}, {:permit => '_100_'}]) }.to raise_error(Puppet::Error, /The regex _10X\$ is invalid/)
    end

    it 'should not support [{:reject => \'_100$\'}, {:permit => \'_100_\'}] as a value' do
      expect { described_class.new(:name => 'as100', :rules => [{:reject => '_100$'}, {:permit => '_100_'}]) }.to raise_error(Puppet::Error, /Use the action permit or deny instead of reject/)
    end

    it 'should not support a string as a value' do
      expect { described_class.new(:name => 'as100', :rules => 'permit => _100$') }.to raise_error(Puppet::Error, /Use a hash { action => regex }/)
    end

    it 'should contain [{:permit => \'_100$\'}]' do
      expect(described_class.new(:name => 'as100', :rules => {:permit => '_100$'})[:rules]).to eq([{:permit => '_100$'}])
    end

    it 'should contain [{:permit => \'_100$\'}, {:permit => \'_100_\'}]' do
      expect(described_class.new(:name => 'as100', :rules => [{:permit => '_100$'}, {:permit => '_100_'}])[:rules]).to eq([{:permit => '_100$'}, {:permit => '_100_'}])
    end
  end
end