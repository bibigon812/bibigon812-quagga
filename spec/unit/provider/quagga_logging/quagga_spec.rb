require 'spec_helper'

describe Puppet::Type.type(:quagga_logging).provider(:quagga) do
  let(:resource) do
    Puppet::Type.type(:quagga_logging).new(
      provider: provider,
      name:     'file',
      ensure:   :present,
      filename: '/tmp/file.log',
      level:    :warnings,
    )
  end

  let(:provider) do
    described_class.new(
      name:     'file',
      ensure:   :present,
      provider: :quagga,
      filename: '/tmp/file.log',
      level:    :warnings,
    )
  end

  let(:provider1) do
    described_class.new(
      name:     'syslog',
      ensure:   :present,
      provider: :quagga,
      facility: 'level7',
      level:    :warnings,
    )
  end

  let(:output) do
    '!
log file /tmp/file.log warnings
log stdout errors
log syslog
log facility local7'
  end

  describe 'instances' do
    it 'should have an instance method' do
      expect(described_class).to respond_to :instances
    end
  end

  describe 'prefetch' do
    it 'should have a prefetch method' do
      expect(described_class).to respond_to :prefetch
    end
  end

  context 'running-config' do
    before :each do
      described_class.expects(:vtysh).with(
        '-c', 'show running-config'
      ).returns output
    end

    it 'should return 3 resources' do
      expect(described_class.instances.size).to eq(3)
    end

    it "should return quagga_logging 'file' resource" do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        provider: :quagga,
        name: 'file',
        filename: '/tmp/file.log',
        level: :warnings,
      })
    end

    it "should return quagga_logging 'stdout' resource" do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        provider: :quagga,
        name: 'stdout',
        level: :errors,
      })
    end

    it "should return quagga_logging 'syslog' resource" do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq({
        ensure: :present,
        provider: :quagga,
        name: 'syslog',
        level: :errors,
      })
    end
  end

  describe 'prefetch' do
    let(:resources) do
      {
        'file' => resource
      }
    end

    before :each do
      described_class.stubs(:vtysh).with(
          '-c', 'show running-config'
      ).returns output
    end

    it 'should find provider for resource' do
      described_class.prefetch(resources)
      expect(resources.values.first.provider).to eq(described_class.instances[0])
    end
  end

  # describe '#create' do
  #   before do
  #     provider.stubs(:exists?).returns(false)
  #   end

  #   it 'should has all values' do
  #     resource[:name] = 'file'
  #     resource[:ensure] = :present
  #     resource[:filename] = '/tmp/file.log'
  #     resource[:level] = :warnings

  #     provider.create
  #     expect(provider.class_variable_get(@property_hash)[:ensure]).to eq(:present)
  #   end

  #   it 'should has facility' do
  #     resource[:ensure] = :present
  #     resource[:name] = 'syslog'
  #     resource[:facility] = :local7

  #     provider.create
  #     expect(provider.class_variable_get(@property_hash)[:ensure]).to eq(:present)
  #   end
  # end
  describe '#flush' do
    before do
      provider.stubs(:exists?).returns(true)
      provider1.stubs(:exists?).returns(true)
    end

    it 'should update all values for quagga_logging file' do
      resource[:ensure] = :present
      provider.filename = '/tmp/file1.log'
      provider.level = :errors
      provider.expects(:vtysh).with([
        '-c', 'configure terminal',
        '-c', 'log file /tmp/file1.log errors',
        '-c', 'end',
        '-c', 'write memory',
      ])
      provider.flush
    end

    it 'should update facility value for quagga_logging syslog' do
      resource[:ensure] = :present
      provider1.filename = '/tmp/file1.log'
      provider1.level = :errors
      provider1.expects(:vtysh).with([
        '-c', 'configure terminal',
        '-c', 'log syslog errors',
        '-c', 'end',
        '-c', 'write memory',
      ])
      provider1.flush
    end
  end
end
