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

    [:abr_type, :default_information, :area, :redistribute, :router_id,
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
      expect { described_class.new(:name => 'ospf', :default_information => { :originate => :true }) }.to_not raise_error
    end

    it 'should support {:originate => :false} as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => { :originate => :false }) }.to_not raise_error
    end

    it 'should support hash as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => { :originate => :true, :always => :true }) }.to_not raise_error
    end

    it 'should support hash as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => { 'originate' => 'true', 'always' => 'true' }) }.to_not raise_error
    end

    it 'should support hash as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => { 'originate' => true, 'always' => true }) }.to_not raise_error
    end

    it 'should not support :origenate as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => :origenate) }.to raise_error(Puppet::Error, /This property should be a Hash/)
    end

    it 'should not support { :originate => true, :metric_type => \'A\' } as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => { :originate => true, :metric_type => 'A' }) }.to raise_error(Puppet::Error, /Value of metric-type must be 1 or 2 but not A/)
    end

    it 'should not support { :originate => true, :metric_type => 3 } as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => { :originate => true, :metric_type => 3 }) }.to raise_error(Puppet::Error, /Value of metric-type must be 1 or 2 but not 3/)
    end

    it 'should not support { :originate => true, :metric => -3 } as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => { :originate => true, :metric => -3 }) }.to raise_error(Puppet::Error, /Value of metric must be between 0 and 16777214 but not -3/)
    end

    it 'should not support { \'originate\' => {\'metric-type => 2}}\' as a value' do
      expect { described_class.new(:name => 'ospf', :default_information => { 'originate' => { 'metric-type' => 2}}) }.to raise_error(Puppet::Error, /is not a boolean value/)
    end

    it 'should contain { :originate => :true , :always => :true, :metric_type => 2, :route_map => \'ABCD\' }' do
      expect(described_class.new(:name => 'ospf', :default_information => { 'originate' => :true, 'always' => true, 'metric-type' => 2, 'route-map' => 'ABCD' })[:default_information]).to eq(:originate => :true, :always => :true, :metric_type => 2, :route_map => 'ABCD')
    end

    it 'should contain { :originate => :true, :metric_type => 2}' do
      expect(described_class.new(:name => 'ospf', :default_information => { :originate => :true, 'metric-type' => 2 })[:default_information]).to eq(:originate => :true, :metric_type => 2)
    end

    it 'should contain { :originate => :true, :metric_type\' => 2}' do
      expect(described_class.new(:name => 'ospf', :default_information => { :originate => :true, 'metric-type' => '2' })[:default_information]).to eq(:originate => :true, :metric_type => 2)
    end
  end

  describe 'area' do
    it 'should not support a String as a value' do
      expect { described_class.new(:name => 'ospf', :area => '{ 0.0.0.0 => { network => 10.0.0.0/24 } }') }.to raise_error(Puppet::Error, /This property should be a Hash/)
    end

    it 'should support a Hash as a value' do
      expect { described_class.new(:name => 'ospf', :area => { '10.0.0.0' => { :network => '10.0.0.0/24' } }) }.to_not raise_error
    end

    it 'should not support { \'0.0.0.0\' => { \'network\' => \'0.0.0.0\' } } as a value' do
      expect { described_class.new(:name => 'ospf', :area => { '0.0.0.0' => { 'network' => '0.0.0.0' } }) }.to raise_error(Puppet::Error, /is not a valid network/)
    end

    it 'should not support { \'0.0.0.0\' => { \'netwark\' => \'10.0.0.0/24\' } } as a value' do
      expect { described_class.new(:name => 'ospf', :area => { '0.0.0.0' => { 'netwark' => '10.0.0.0/24' } }) }.to raise_error(Puppet::Error, /OSPF area does not contain this attribute: netwark/)
    end

    it 'should not support { \'0.0.0.0\' => { \'network\' => \'10.0.0.0\' } } as a value' do
      expect { described_class.new(:name => 'ospf', :area => { '0.0.0.0' => { :network => '10.0.0.0' } }) }.to raise_error(Puppet::Error, /is not a valid network/)
    end

    it 'should contain { \'0.0.0.0\' => { :network => \'10.0.0.0/24\' } }\'' do
      expect(described_class.new(:name => 'ospf', :area => { '0.0.0.0' => { :network => '10.0.0.0/24' } })[:area]).to eq('0.0.0.0' => { :network => [ '10.0.0.0/24' ] })
    end

    it 'should contain { \'0.0.0.0\' => { :network => [ \'10.0.0.0/24\', \'172.16.0.0/24\' ] } }' do
      expect(described_class.new(:name => 'ospf', :area => { '0.0.0.0' => { :network => [ '10.0.0.0/24', '172.16.0.0/24' ] } })[:area]).to eq('0.0.0.0' => { :network => [ '10.0.0.0/24', '172.16.0.0/24' ] })
    end
  end

  describe 'redistribute' do
    it 'should not support a String as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => '{ :connected => { :route_map => \'ABCD\' } }') }.to raise_error(Puppet::Error, /This property should be a Hash/)
    end

    it 'should support a Hash as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => { :connected => true }) }.to_not raise_error
    end

    it 'should not support { \'bgp\' => { \'metric-type\' => \'5\' } } as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => { 'bgp' => { 'metric-type' => '5' } }) }.to raise_error(Puppet::Error, /Value of metric-type must be 1 or 2 but not 5/)
    end

    it 'should not support { \'bgp\' => { \'metric\' => \'-5\' } } as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => { 'bgp' => { 'metric' => '-5' } }) }.to raise_error(Puppet::Error, /Value of metric must be between 0 and 16777214 but not -5/)
    end

    it 'should support { :bgp => { :metric_type => 2 } } as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => { :bgp => { :metric_type => 2 } }) }.to_not raise_error
    end

    it 'should support { :bgp => { :metric => 10 } } as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => { :bgp => { :metric => 10 } }) }.to_not raise_error
    end

    it 'should support { :bgp => { :route_map => \'ABCD\' } } as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => { :bgp => { :route_map => 'ABCD' } }) }.to_not raise_error
    end

    it 'should support { :bgp => { :metric => 10, :metric_type => 2, :route_map => \'ABCD\' } } as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => { :bgp => { :metric => 10, :metric_type => 2, :route_map => 'ABCD' } }) }.to_not raise_error
    end

    it 'should support { :bgp => { :metric => 10 }, :connected => true } as a value' do
      expect { described_class.new(:name => 'ospf', :redistribute => { :bgp => { :metric => 10 }, :connected => true }) }.to_not raise_error
    end

    it 'should contain { :bgp => { :metric => 10, :metric_type => 2, :route_map => \'ABCD\' } }' do
      expect(described_class.new(:name => 'ospf', :redistribute => { :bgp => { :metric => 10, :metric_type => 2, :route_map => 'ABCD' } })[:redistribute]).to eq(:bgp => { :metric => 10, :metric_type => 2, :route_map => 'ABCD' })
    end

    it 'should contain { \'bgp\' => { \'metric\' => 10, \'metric-type\' => 2, \'route-map\' => \'ABCD\' } }' do
      expect(described_class.new(:name => 'ospf', :redistribute => { 'bgp' => { 'metric' => 10, 'metric-type' => 2, 'route-map' => 'ABCD' } })[:redistribute]).to eq(:bgp => { :metric => 10, :metric_type => 2, :route_map => 'ABCD' })
    end

    it 'should contain { :bgp => { :metric => 10, :metric_type => 2, :route_map => \'ABCD\' }, :connected => true }' do
      expect(described_class.new(:name => 'ospf', :redistribute => { :bgp => { :metric => 10, :metric_type => 2, :route_map => 'ABCD' }, :connected => true })[:redistribute]).to eq({ :bgp => { :metric => 10, :metric_type => 2, :route_map => 'ABCD' }, :connected => :true })
    end
  end
end
