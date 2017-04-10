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

    [:abr_type, :default_information, :redistribute, :router_id,
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
    it 'should support String as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'originate') }.to_not raise_error
    end

    it 'should support String as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'originate always') }.to_not raise_error
    end

    it 'should support String as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'originate always metric 100 metric-type 1') }.to_not raise_error
    end

    it 'should support String as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'originate always metric 100') }.to_not raise_error
    end

    it 'should support String as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'originate metric 100 route-map ABCD') }.to_not raise_error
    end

    it 'should support String as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'originate route-map ABCD') }.to_not raise_error
    end

    it 'should not support \'origenate\' as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'origenate') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support \'originate metric-type A\' as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'originate metric-type A') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support \'originate metric-type 3\' as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'originate metric-type 3') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should not support \'originate metric -3\' as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => 'originate metric -3') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should contain \'originate always metric-type 2 route_map ABCD\'' do
      expect(described_class.new(:name => 'ospf', :default_information => 'originate always metric-type 2 route-map ABCD')[:default_information]).to eq('originate always metric-type 2 route-map ABCD')
    end

    it 'should contain \'originate metric_type 2' do
      expect(described_class.new(:name => 'ospf', :default_information => 'originate metric-type 2')[:default_information]).to eq('originate metric-type 2')
    end
  end

  # describe 'area' do
  #   it 'should not support \'0.0.0.0\' as a value' do
  #     expect { described_class.new(:name => 'ospf', :area => '0.0.0.0') }.to raise_error(Puppet::Error, /Invalid value/)
  #   end
  #
  #   it 'should support \'0.0.0.0 authentication message-digest\' as a value' do
  #     expect { described_class.new(:name => 'ospf', :area => '0.0.0.0 authentication message-digest') }.to_not raise_error
  #   end
  #
  #   it 'should support \'0.0.0.0 default-cost 100\' as a value' do
  #     expect { described_class.new(:name => 'ospf', :area => '0.0.0.0 default-cost 100') }.to_not raise_error
  #   end
  #
  #   it 'should support \'0.0.0.0 export-list ABCD\' as a value' do
  #     expect { described_class.new(:name => 'ospf', :area => '0.0.0.0 export-list ABCD') }.to_not raise_error
  #   end
  #
  #   it 'should support \'0.0.0.0 filter-list prefix ABCD-EF\' as a value' do
  #     expect { described_class.new(:name => 'ospf', :area => '0.0.0.0 filter-list prefix ABCD-EF') }.to_not raise_error
  #   end
  #
  #   it 'should contain \'0.0.0.0 nssa\'' do
  #     expect(described_class.new(:name => 'ospf', :area => '0.0.0.0 nssa')[:area]).to eq('0.0.0.0 nssa')
  #   end
  #
  #   it 'should contain \'0.0.0.0 nssa translate-always no-summary\'' do
  #     expect(described_class.new(:name => 'ospf', :area => '0.0.0.0 nssa translate-always no-summary')[:area]).to eq('0.0.0.0 nssa translate-always no-summary')
  #   end
  # end

  describe 'redistribute' do
    it 'should support a String as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => 'connected route-map ABCD-EF') }.to_not raise_error
    end

    it 'should support a String as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => 'connected') }.to_not raise_error
    end

    it 'should not support \'bgp metric-type 5\' as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => 'bgp metric-type 5') }.to raise_error(Puppet::Error, /Invalid value/)
    end

    it 'should support [ \'bgp metric 100\', \'connected\' ] as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => [ 'bgp metric 100', 'connected' ]) }.to_not raise_error
    end

    it 'should support [ \'bgp metric-type 2\', \'rip route-map ABCD-EF\' ] as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => [ 'bgp metric-type 2', 'rip route-map ABCD-EF' ]) }.to_not raise_error
    end

    it 'should support \'bgp metric 10\' as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => 'bgp metric 10') }.to_not raise_error
    end

    it 'should support \'bgp route-map ABCD-EF\' as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => 'bgp route-map ABCD-EF') }.to_not raise_error
    end

    it 'should support \'bgp metric 10 metric-type 2 route-map ABCD-EF\' as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => 'bgp metric 10 metric-type 2 route-map ABCD-EF') }.to_not raise_error
    end

    it 'should support [ \'bgp metric 10\' , \'connected\' ] as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => [ 'bgp metric 10', 'connected' ]) }.to_not raise_error
    end

    it 'should contain \'bgp metric 10 metric-type 2 route-map ABCD-EF\'' do
      expect(described_class.new(:name => 'ospf', :redistribute => 'bgp metric 10 metric-type 2 route-map ABCD-EF')[:redistribute]).to eq([ 'bgp metric 10 metric-type 2 route-map ABCD-EF' ])
    end

    it 'should contain \'bgp metric 10 metric-type  2 route-map ABCD-EF\'' do
      expect(described_class.new(:name => 'ospf', :redistribute => 'bgp metric 10 metric-type 2 route-map ABCD-EF')[:redistribute]).to eq([ 'bgp metric 10 metric-type 2 route-map ABCD-EF' ])
    end

    it 'should contain [ \'bgp metric 10 metric-type 2 route-map ABCD-EF\', \'connected\' ]' do
      expect(described_class.new(:name => 'ospf', :redistribute => [ 'bgp metric 10 metric-type 2 route-map ABCD-EF', 'connected' ])[:redistribute]).to eq([ 'bgp metric 10 metric-type 2 route-map ABCD-EF', 'connected' ])
    end
  end

  describe 'router_id' do
    it 'should support \'1.1.1.1\' as a value' do
      expect { described_class.new(:name => 'ospf', :router_id => '1.1.1.1') }.to_not raise_error
    end

    it 'should contain \'1.1.1.1\'' do
      expect(described_class.new(:name => 'ospf', :router_id => '1.1.1.1')[:router_id]).to eq('1.1.1.1')
    end
  end
end
