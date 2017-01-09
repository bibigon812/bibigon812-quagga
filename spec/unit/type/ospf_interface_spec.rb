require 'spec_helper'

describe Puppet::Type.type(:ospf_interface) do
  let(:networking_service) do
    @provider_class = describe_class.provide(:ospf_interface) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:ospf_interface)
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

    [:cost, :dead_interval, :hello_interval, :mtu_ignore, :network_type,
      :priority, :retransmit_interval, :transmit_delay].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support up as a value' do
        expect { described_class.new(:name => 'foo', :ensure => :present) }.to_not raise_error
      end

      it 'should support absent as a value' do
        expect { described_class.new(:name => 'foo', :ensure => :absent) }.to_not raise_error
      end

      it 'should not support other values' do
        expect { described_class.new(:name => 'foo', :ensure => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'cost' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :cost => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :cost => 0) }.to raise_error(Puppet::Error, /Cost: 1-65535/)
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :cost => 65536) }.to raise_error(Puppet::Error, /Cost: 1-65535/)
      end
    end

    describe 'dead_interval' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :dead_interval => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :dead_interval => 0) }.to raise_error(Puppet::Error, /Interval after which a neighbor is declared dead: 1-65535 seconds/)
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :dead_interval => 65536) }.to raise_error(Puppet::Error, /Interval after which a neighbor is declared dead: 1-65535 seconds/)
      end
    end

    describe 'mtu_ignore' do
      it 'should support true as a value' do
        expect { described_class.new(:name => 'foo', :mtu_ignore => true) }.to_not raise_error
      end

      it 'should support :true as a value' do
        expect { described_class.new(:name => 'foo', :mtu_ignore => :true) }.to_not raise_error
      end

      it 'should support false as a value' do
        expect { described_class.new(:name => 'foo', :mtu_ignore => false) }.to_not raise_error
      end

      it 'should support :false as a value' do
        expect { described_class.new(:name => 'foo', :mtu_ignore => :false) }.to_not raise_error
      end

      it 'should not support foo as a value' do
        expect { described_class.new(:name => 'foo', :mtu_ignore => :foo) }.to raise_error(Puppet::Error, /Invalid value/)
      end
    end

    describe 'network_type' do
      it 'should support :broadcast as value' do
        expect { described_class.new(:name => 'foo', :network_type => :broadcast) }.to_not raise_error
      end

      it 'should support :non_broadcast as value' do
        expect { described_class.new(:name => 'foo', :network_type => :non_broadcast) }.to_not raise_error
      end

      it 'should support non-broadcast as value' do
        expect { described_class.new(:name => 'foo', :network_type => 'non-broadcast') }.to_not raise_error
      end

      it 'should support :point_to_multipoint as value' do
        expect { described_class.new(:name => 'foo', :network_type => :point_to_multipoint) }.to_not raise_error
      end

      it 'should support point-to-multipoint as value' do
        expect { described_class.new(:name => 'foo', :network_type => 'point-to-multipoint') }.to_not raise_error
      end

      it 'should support :point_to_point as value' do
        expect { described_class.new(:name => 'foo', :network_type => :point_to_point) }.to_not raise_error
      end

      it 'should support point-to-point as value' do
        expect { described_class.new(:name => 'foo', :network_type => 'point-to-point') }.to_not raise_error
      end
    end

    describe 'priority' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :priority => 100) }.to_not raise_error
      end

      it 'should not support -1 as a value' do
        expect { described_class.new(:name => 'foo', :priority => -1) }.to raise_error(Puppet::Error, /Priority: 0-255/)
      end

      it 'should not support 256 as a value' do
        expect { described_class.new(:name => 'foo', :priority => 256) }.to raise_error(Puppet::Error, /Priority: 0-255/)
      end
    end

    describe 'retransmit_interval' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :retransmit_interval => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :retransmit_interval => 0) }.to raise_error(Puppet::Error, /Time between retransmitting lost link state advertisements: 3-65535 seconds/)
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :retransmit_interval => 65536) }.to raise_error(Puppet::Error, /Time between retransmitting lost link state advertisements: 3-65535 seconds/)
      end
    end

    describe 'transmit_delay' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :transmit_delay => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :transmit_delay => 0) }.to raise_error(Puppet::Error, /Link state transmit delay: 1-65535 seconds/)
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :transmit_delay => 65536) }.to raise_error(Puppet::Error, /Link state transmit delay: 1-65535 seconds/)
      end
    end
  end
end
