require 'spec_helper'

describe Puppet::Type.type(:quagga_route_map) do
  let(:provider) do
    @provider_class = describe_class.provide(:quagga_route_map) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:quagga_route_map)
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

    [:action, :match, :on_match, :set].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support present as a value' do
        expect { described_class.new(:name => 'ROUTE_MAP:10', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'ROUTE_MAP:10', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'ROUTE_MAP:10', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end
  end

  describe 'name' do
    it 'should support as100 as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10') }.to_not raise_error
    end

    it 'should support as100 as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10') }.to_not raise_error
    end
  end

  describe 'action' do
    it 'should support \'permit\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :action => 'permit') }.to_not raise_error
    end

    it 'should support \'deny\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :action => 'deny') }.to_not raise_error
    end

    it 'should support :permit as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :action => :permit) }.to_not raise_error
    end

    it 'should support :deny as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :action => :deny) }.to_not raise_error
    end

    it 'should not support \'reject\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :action => 'reject') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain :permit' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :action => 'permit')[:action]).to eq(:permit)
    end

    it 'should contain :deny' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :action => 'deny')[:action]).to eq(:deny)
    end

    it 'should contain :permit' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :action => :permit)[:action]).to eq(:permit)
    end
  end

  describe 'match' do
    it 'should support \'as-path WORD\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :match => 'as-path WORD') }.to_not raise_error
    end

    it 'should support \'community WORD\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :match => 'community WORD') }.to_not raise_error
    end

    it 'should support \'community WORD exact-match\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :match => 'community WORD exact-match') }.to_not raise_error
    end

    it 'should support [\'local-preference 200\', \'origin incomplete\'] as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :match => ['local-preference 200', 'origin incomplete']) }.to_not raise_error
    end

    it 'should not support \'pear local\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :match => 'pear local') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain [\'probability 50\', \'tag 100\']' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :match => ['probability 50', 'tag 100'])[:match]).to eq(['probability 50', 'tag 100'])
    end

    it 'should contain [\'ip address 100\']' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :match => 'ip address 100')[:match]).to eq(['ip address 100'])
    end

    it 'should contain [\'ip address prefix-list WORD\']' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :match => 'ip address prefix-list WORD')[:match]).to eq(['ip address prefix-list WORD'])
    end
  end

  describe 'on_math' do
    it 'should support \'goto 100\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :on_match => 'goto 100') }.to_not raise_error
    end

    it 'should support \'next\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :on_match => 'next') }.to_not raise_error
    end

    it 'should not support \'goto A\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :on_match => 'goto A') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain \'goto 100\'' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :on_match => 'goto 100')[:on_match]).to eq('goto 100')
    end

    it 'should contain \'next\'' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :on_match => 'next')[:on_match]).to eq('next')
    end
  end

  describe 'set' do
    it 'should support \'community 100:1 100:2 additive\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :set => 'community 100:1 100:2 additive') }.to_not raise_error
    end

    it 'should support \'community 100:1\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :set => 'community 100:1') }.to_not raise_error
    end

    it 'should support \'aggregator as 100\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :set => 'aggregator as 100') }.to_not raise_error
    end

    it 'should support [\'local-preference 200\', \'ip next-hop peer-address\'] as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :set => ['local-preference 200', 'ip next-hop peer-address']) }.to_not raise_error
    end

    it 'should not support \'teg local\' as a value' do
      expect { described_class.new(:name => 'ROUTE_MAP:10', :set => 'pear local') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain [\'src 1.1.1.1\', \'tag 100\']' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :set => ['src 1.1.1.1', 'tag 100'])[:set]).to eq(['src 1.1.1.1', 'tag 100'])
    end

    it 'should contain [\'metric +rtt\']' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :set => 'metric +rtt')[:set]).to eq(['metric +rtt'])
    end

    it 'should contain [\'originator-id 1.1.1.1\']' do
      expect(described_class.new(:name => 'ROUTE_MAP:10', :set => 'originator-id 1.1.1.1')[:set]).to eq(['originator-id 1.1.1.1'])
    end
  end
end