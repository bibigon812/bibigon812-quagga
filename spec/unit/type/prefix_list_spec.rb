require 'spec_helper'

describe Puppet::Type.type(:prefix_list) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:prefix_list) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:prefix_list)
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

    [ :action, :prefix, :ge, :le ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'CONNECTED-NETWORK:10', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'CONNECTED-NETWORK:10', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'CONNECTED-NETWORK:10', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'name' do
    it 'should support as100 as a value' do
      expect { described_class.new(:name => 'prefix_list:10') }.to_not raise_error
    end

    it 'should support as100 as a value' do
      expect { described_class.new(:name => 'prefix-list:100') }.to_not raise_error
    end

    it 'should not support as100 as a value' do
      expect { described_class.new(:name => 'prefix_list') }.to raise_error(Puppet::Error, /Invalid value/)
    end
  end

  describe 'action' do
    it 'should support :permit as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :action => :permit) }.to_not raise_error
    end

    it 'should support \'permit\' as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :action => 'permit') }.to_not raise_error
    end

    it 'should support :permit as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :action => :deny) }.to_not raise_error
    end

    it 'should support \'permit\' as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :action => 'deny') }.to_not raise_error
    end

    it 'should not support a dot in the string' do
      expect { described_class.new(:name => 'foo-prefix:10', :action => 'reject') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain :permit' do
      expect(described_class.new(:name => 'foo-prefix:10', :action => 'permit')[:action]).to eq(:permit)
    end

    it 'should contain :deny' do
      expect(described_class.new(:name => 'foo-prefix:10', :action => 'deny')[:action]).to eq(:deny)
    end
  end

  describe 'prefix' do
    it 'should support :permit as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :prefix => '192.168.0.0/16') }.to_not raise_error
    end

    it 'should support \'permit\' as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :prefix => '172.16.0.0/12') }.to_not raise_error
    end

    it 'should support :any as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :prefix => :any) }.to_not raise_error
    end

    it 'should support \'any\' as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :prefix => 'any') }.to_not raise_error
    end

    it 'should not support a dot in the string' do
      expect { described_class.new(:name => 'foo-prefix:10', :prefix => 'reject') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain :permit' do
      expect(described_class.new(:name => 'foo-prefix:10', :prefix => '192.168.0.0/16')[:prefix]).to eq('192.168.0.0/16')
    end

    it 'should contain :deny' do
      expect(described_class.new(:name => 'foo-prefix:10', :prefix => 'any')[:prefix]).to eq('any')
    end
  end

  describe 'proto' do
    it 'should support :permit as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :proto => 'ip') }.to_not raise_error
    end

    it 'should support \'permit\' as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :proto => 'ipv6') }.to_not raise_error
    end

    it 'should support :any as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :proto => :ip) }.to_not raise_error
    end

    it 'should support \'any\' as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :proto => :ipv6) }.to_not raise_error
    end

    it 'should not support a dot in the string' do
      expect { described_class.new(:name => 'foo-prefix:10', :proto => :ipv5) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain :permit' do
      expect(described_class.new(:name => 'foo-prefix:10', :proto => 'ip')[:proto]).to eq(:ip)
    end

    it 'should contain :deny' do
      expect(described_class.new(:name => 'foo-prefix:10', :proto => :ipv6)[:proto]).to eq(:ipv6)
    end
  end

  describe 'ge' do
    it 'should support :permit as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :ge => '24') }.to_not raise_error
    end

    it 'should support \'permit\' as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :ge => 16) }.to_not raise_error
    end

    it 'should support :any as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :ge => 8) }.to_not raise_error
    end

    it 'should not support a dot in the string' do
      expect { described_class.new(:name => 'foo-prefix:10', :ge => 'reject') }.to raise_error(Puppet::Error, /Minimum prefix length: 1-32/)
    end

    it 'should contain :permit' do
      expect(described_class.new(:name => 'foo-prefix:10', :ge => '24')[:ge]).to eq(24)
    end

    it 'should contain :deny' do
      expect(described_class.new(:name => 'foo-prefix:10', :ge => 16)[:ge]).to eq(16)
    end
  end

  describe 'le' do
    it 'should support :permit as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :le => '24') }.to_not raise_error
    end

    it 'should support \'permit\' as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :le => 16) }.to_not raise_error
    end

    it 'should support :any as a value' do
      expect { described_class.new(:name => 'foo-prefix:10', :le => 8) }.to_not raise_error
    end

    it 'should not support a dot in the string' do
      expect { described_class.new(:name => 'foo-prefix:10', :le => 'reject') }.to raise_error(Puppet::Error, /Maximum prefix length: 1-32/)
    end

    it 'should contain :permit' do
      expect(described_class.new(:name => 'foo-prefix:10', :le => '24')[:le]).to eq(24)
    end

    it 'should contain :deny' do
      expect(described_class.new(:name => 'foo-prefix:10', :le => 16)[:le]).to eq(16)
    end
  end
end
