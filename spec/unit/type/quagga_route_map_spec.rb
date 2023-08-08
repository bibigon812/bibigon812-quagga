require 'spec_helper'

describe Puppet::Type.type(:quagga_route_map) do
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

  before :each do
    allow(Puppet::Type.type(:quagga_route_map)).to receive(:defaultprovider).and_return(providerclass)
  end

  after :each do
    described_class.unprovide(:quagga_route_map)
  end

  it 'has :name, :sequence be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:action, :match, :on_match, :set].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'supports present as a value' do
        expect { described_class.new(name: 'ROUTE_MAP 10', ensure: :present) }.not_to raise_error
      end

      it 'supports absent as a value' do
        expect { described_class.new(name: 'ROUTE_MAP 10', ensure: :absent) }.not_to raise_error
      end

      it 'does not support other values' do
        expect { described_class.new(name: 'ROUTE_MAP 10', ensure: :foo) }.to raise_error Puppet::Error, %r{Invalid value}
      end
    end
  end

  describe 'name' do
    it 'supports \'ROUTE_MAP 10\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10') }.not_to raise_error
    end

    it 'supports \'route-map 10\' as a value' do
      expect { described_class.new(name: 'route-map 10') }.not_to raise_error
    end
  end

  describe 'action' do
    it 'supports \'permit\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', action: 'permit') }.not_to raise_error
    end

    it 'supports \'deny\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', action: 'deny') }.not_to raise_error
    end

    it 'supports :permit as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', action: :permit) }.not_to raise_error
    end

    it 'supports :deny as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', action: :deny) }.not_to raise_error
    end

    it 'does not support \'reject\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', action: 'reject') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains :permit when passed string "permit"' do
      expect(described_class.new(name: 'ROUTE_MAP 10', action: 'permit')[:action]).to eq(:permit)
    end

    it 'contains :deny' do
      expect(described_class.new(name: 'ROUTE_MAP 10', action: 'deny')[:action]).to eq(:deny)
    end

    it 'contains :permit when passed symbol :permit' do
      expect(described_class.new(name: 'ROUTE_MAP 10', action: :permit)[:action]).to eq(:permit)
    end
  end

  describe 'match' do
    it 'supports \'as-path WORD\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', match: 'as-path WORD') }.not_to raise_error
    end

    it 'supports \'community WORD\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', match: 'community WORD') }.not_to raise_error
    end

    it 'supports \'community WORD exact-match\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', match: 'community WORD exact-match') }.not_to raise_error
    end

    it 'supports [\'local-preference 200\', \'origin incomplete\'] as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', match: ['local-preference 200', 'origin incomplete']) }.not_to raise_error
    end

    it 'does not support \'pear local\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', match: 'pear local') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains [\'probability 50\', \'tag 100\']' do
      expect(described_class.new(name: 'ROUTE_MAP 10', match: ['probability 50', 'tag 100'])[:match]).to eq(['probability 50', 'tag 100'])
    end

    it 'contains [\'ip address 100\']' do
      expect(described_class.new(name: 'ROUTE_MAP 10', match: 'ip address 100')[:match]).to eq(['ip address 100'])
    end

    it 'contains [\'ip address prefix-list WORD\']' do
      expect(described_class.new(name: 'ROUTE_MAP 10', match: 'ip address prefix-list WORD')[:match]).to eq(['ip address prefix-list WORD'])
    end
  end

  describe 'on_math' do
    it 'supports \'goto 100\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', on_match: 'goto 100') }.not_to raise_error
    end

    it 'supports \'next\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', on_match: 'next') }.not_to raise_error
    end

    it 'does not support \'goto A\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', on_match: 'goto A') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains \'goto 100\'' do
      expect(described_class.new(name: 'ROUTE_MAP 10', on_match: 'goto 100')[:on_match]).to eq('goto 100')
    end

    it 'contains \'next\'' do
      expect(described_class.new(name: 'ROUTE_MAP 10', on_match: 'next')[:on_match]).to eq('next')
    end
  end

  describe 'set' do
    it 'supports \'community 100 1 100 2 additive\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', set: 'community 100:1 100:2 additive') }.not_to raise_error
    end

    it 'supports \'community 100 1\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', set: 'community 100:1') }.not_to raise_error
    end

    it 'supports \'aggregator as 100\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', set: 'aggregator as 100') }.not_to raise_error
    end

    it 'supports [\'local-preference 200\', \'ip next-hop peer-address\'] as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', set: ['local-preference 200', 'ip next-hop peer-address']) }.not_to raise_error
    end

    it 'does not support \'teg local\' as a value' do
      expect { described_class.new(name: 'ROUTE_MAP 10', set: 'pear local') }.to raise_error Puppet::Error, %r{Invalid value}
    end

    it 'contains [\'src 1.1.1.1\', \'tag 100\']' do
      expect(described_class.new(name: 'ROUTE_MAP 10', set: ['src 1.1.1.1', 'tag 100'])[:set]).to eq(['src 1.1.1.1', 'tag 100'])
    end

    it 'contains [\'metric +rtt\']' do
      expect(described_class.new(name: 'ROUTE_MAP 10', set: 'metric +rtt')[:set]).to eq(['metric +rtt'])
    end

    it 'contains [\'originator-id 1.1.1.1\']' do
      expect(described_class.new(name: 'ROUTE_MAP 10', set: 'originator-id 1.1.1.1')[:set]).to eq(['originator-id 1.1.1.1'])
    end
  end
end
