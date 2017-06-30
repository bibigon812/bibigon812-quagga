require 'spec_helper'

describe Puppet::Type.type(:quagga_interface) do
  let(:quagga_interface) do
    @provider_class = describe_class.provide(:quagga_interface) {
      mk_resource_methods
    }
    @provider_class.stub(:suitable?).return true
    @provider_class
  end

  before :each do
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  after :each do
    described_class.unprovide(:quagga_interface)
  end

  it 'should have :name be its namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:ospf_cost, :ospf_dead_interval, :ospf_hello_interval, :ospf_mtu_ignore, :ospf_network,
     :ospf_priority, :ospf_retransmit_interval, :ospf_transmit_delay,
     :igmp, :pim_ssm, :igmp_query_interval, :igmp_query_max_response_time_dsec,
     :bandwidth, :link_detect, :multicast,
    ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'ip_address' do
      it 'should support 10.0.0.1/24 as a value' do
        expect { described_class.new(:name => 'foo', :ip_address => '10.0.0.1/24') }.to_not raise_error
      end

      it 'should not support 500.0.0.1/24 as a value' do
        expect { described_class.new(:name => 'foo', :ip_address => '500.0.0.1/24') }.to raise_error Puppet::Error, /Not a valid ip address/
      end

      it 'should not support 10.0.0.1 as a value' do
        expect { described_class.new(:name => 'foo', :ip_address => '10.0.0.1') }.to raise_error Puppet::Error, /Prefix length is not specified/
      end

      it 'should contain 10.0.0.1' do
        expect(described_class.new(:name => 'foo', :ip_address => '10.0.0.1/24')[:ip_address]).to eq(['10.0.0.1/24'])
      end
    end

    describe 'ospf_cost' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_cost => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_cost => 0) }.to raise_error(Puppet::Error, /OSPF cost/)
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_cost => 65536) }.to raise_error(Puppet::Error, /OSPF cost/)
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :ospf_cost => 50)[:ospf_cost]).to eq(50)
      end

      it 'should contain 51' do
        expect { described_class.new(:name => 'foo', :ospf_cost => '51') }.to raise_error Puppet::Error, /OSPF cost/
      end
    end

    describe 'ospf_dead_interval' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_dead_interval => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_dead_interval => 0) }.to raise_error Puppet::Error, /OSPF dead interval/
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_dead_interval => 65536) }.to raise_error Puppet::Error, /OSPF dead interval/
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :ospf_dead_interval => 50)[:ospf_dead_interval]).to eq(50)
      end

      it 'should contain 51' do
        expect { described_class.new(:name => 'foo', :ospf_dead_interval => '51') }.to raise_error Puppet::Error, /OSPF dead interval/
      end
    end

    describe 'ospf_hello_interval' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_hello_interval => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_hello_interval => 0) }.to raise_error Puppet::Error, /OSPF hello packets interval/
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_hello_interval => 65536) }.to raise_error Puppet::Error, /OSPF hello packets interval/
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :ospf_hello_interval => 50)[:ospf_hello_interval]).to eq(50)
      end

      it 'should contain 51' do
        expect { described_class.new(:name => 'foo', :ospf_hello_interval => '51') }.to raise_error Puppet::Error, /OSPF hello packets interval/
      end
    end

    [:ospf_mtu_ignore, :igmp, :pim_ssm, :link_detect, :multicast].each do |property|
      describe "#{property}" do
        it 'should support true as a value' do
          expect { described_class.new(:name => 'foo', property => true) }.to_not raise_error
        end

        it 'should support :true as a value' do
          expect { described_class.new(:name => 'foo', property => :true) }.to_not raise_error
        end

        it 'should support :true as a value' do
          expect { described_class.new(:name => 'foo', property => 'true') }.to_not raise_error
        end

        it 'should support false as a value' do
          expect { described_class.new(:name => 'foo', property => false) }.to_not raise_error
        end

        it 'should support :false as a value' do
          expect { described_class.new(:name => 'foo', property => :false) }.to_not raise_error
        end

        it 'should support :false as a value' do
          expect { described_class.new(:name => 'foo', property => 'false') }.to_not raise_error
        end

        it 'should not support foo as a value' do
          expect { described_class.new(:name => 'foo', property => :disabled) }.to raise_error Puppet::Error, /Invalid value/
        end

        it 'should contain enabled' do
          expect(described_class.new(:name => 'foo', property => 'true')[property]).to eq(:true)
        end

        it 'should contain enabled' do
          expect(described_class.new(:name => 'foo', property => :true)[property]).to eq(:true)
        end

        it 'should contain enabled' do
          expect(described_class.new(:name => 'foo', property => true)[property]).to eq(:true)
        end

        it 'should contain disabled' do
          expect(described_class.new(:name => 'foo', property => 'false')[property]).to eq(:false)
        end

        it 'should contain disabled' do
          expect(described_class.new(:name => 'foo', property => :false)[property]).to eq(:false)
        end

        it 'should contain disabled' do
          expect(described_class.new(:name => 'foo', property => false)[property]).to eq(:false)
        end
      end
    end


    describe 'ospf_network' do
      it 'should support :broadcast as value' do
        expect { described_class.new(:name => 'foo', :ospf_network => 'broadcast') }.to_not raise_error
      end

      it 'should support non-broadcast as value' do
        expect { described_class.new(:name => 'foo', :ospf_network => 'non-broadcast') }.to_not raise_error
      end

      it 'should support point-to-multipoint as value' do
        expect { described_class.new(:name => 'foo', :ospf_network => 'point-to-multipoint') }.to_not raise_error
      end

      it 'should support point-to-point as value' do
        expect { described_class.new(:name => 'foo', :ospf_network => 'point-to-point') }.to_not raise_error
      end

      it 'should contain point-to-point' do
        expect(described_class.new(:name => 'foo', :ospf_network => 'point-to-point')[:ospf_network]).to eq('point-to-point')
      end
    end

    describe 'ospf_priority' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_priority => 100) }.to_not raise_error
      end

      it 'should not support -1 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_priority => -1) }.to raise_error(Puppet::Error, /Router OSPF priority/)
      end

      it 'should not support 256 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_priority => 256) }.to raise_error Puppet::Error, /Router OSPF priority/
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :ospf_priority => 50)[:ospf_priority]).to eq(50)
      end

      it 'should contain 51' do
        expect { described_class.new(:name => 'foo', :ospf_priority => '51') }.to raise_error Puppet::Error, /is not an Integer/
      end
    end

    describe 'ospf_ospf_retransmit_interval' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_retransmit_interval => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_retransmit_interval => 0) }.to raise_error Puppet::Error, /OSPF retransmit interval/
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_retransmit_interval => 65536) }.to raise_error Puppet::Error, /OSPF retransmit interval/
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :ospf_retransmit_interval => 50)[:ospf_retransmit_interval]).to eq(50)
      end

      it 'should not support \'51\'' do
        expect { described_class.new(:name => 'foo', :ospf_retransmit_interval => '51') }.to raise_error Puppet::Error, /is not an Integer/
      end
    end

    describe 'ospf_transmit_delay' do
      it 'should support 100 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_transmit_delay => 100) }.to_not raise_error
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_transmit_delay => 0) }.to raise_error Puppet::Error, /OSPF transmit delay/
      end

      it 'should not support 65536 as a value' do
        expect { described_class.new(:name => 'foo', :ospf_transmit_delay => 65536) }.to raise_error Puppet::Error, /OSPF transmit delay/
      end

      it 'should contain 50' do
        expect(described_class.new(:name => 'foo', :ospf_transmit_delay => 50)[:ospf_transmit_delay]).to eq(50)
      end

      it 'should not support \'51\'' do
        expect { described_class.new(:name => 'foo', :ospf_transmit_delay => '51') }.to raise_error Puppet::Error, /is not an Integer/
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
