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

  [:instances, :prefetch].each do |method|
    it "responds to the class method #{method}" do
      expect(described_class).to respond_to(method)
    end
  end

  context 'running-config' do
    before :each do
      expect(described_class).to receive(:vtysh).with(
        '-c', 'show running-config'
      ).and_return(output)
    end

    it 'returns 3 resources' do
      expect(described_class.instances.size).to eq(3)
    end

    it "returns quagga_logging 'file' resource" do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq({
                                                                                           ensure: :present,
        provider: :quagga,
        name: :file,
        filename: '/tmp/file.log',
        level: :warnings,
                                                                                         })
    end

    it "returns quagga_logging 'stdout' resource" do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          provider: :quagga,
          name: :stdout,
          level: :errors,
        },
      )
    end

    it "returns quagga_logging 'syslog' resource" do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq(
        {
          ensure: :present,
          provider: :quagga,
          name: :syslog,
          level: :errors,
        },
      )
    end
  end

  describe 'prefetch' do
    let(:resources) do
      {
        'file' => resource
      }
    end

    before :each do
      allow(described_class).to receive(:vtysh).with(
          '-c', 'show running-config'
        ).and_return output
    end

    it 'finds provider for resource' do
      described_class.prefetch(resources)
      expect(resources.values.first.provider).to eq(described_class.instances[0])
    end
  end

  describe '#create' do
    before :each do
      allow(provider).to receive(:exists?).and_return(true)
    end

    it 'has all values' do
      resource[:name] = 'file'
      resource[:ensure] = :present
      resource[:filename] = '/tmp/file.log'
      resource[:level] = :warnings

      provider.create
      expect(provider.get(:ensure)).to eq(:present)
      expect(provider.get(:name)).to eq(:file)
    end
  end

  describe '#flush' do
    context 'with no existing config' do
      let(:resource) do
        Puppet::Type.type(:quagga_logging).new(
          provider: provider,
          name:     'syslog',
          level:    :warnings,
        )
      end
      let(:provider) do
        described_class.new(
          name:     'syslog',
          provider: :quagga,
          level:    :warnings,
        )
      end

      before(:each) do
        allow(provider).to receive(:exists?).and_return(true)
        provider.level = :warnings
      end

      it 'creates the instance' do
        resource[:ensure] = :present
        expect(provider).to receive(:vtysh).with(
          [
            '-c', 'configure terminal',
            '-c', 'log syslog warnings',
            '-c', 'end',
            '-c', 'write memory'
          ],
        )
        provider.flush
      end
    end

    context 'with existing config' do
      let(:resource1) do
        Puppet::Type.type(:quagga_logging).new(
          provider: provider1,
          name:     :syslog,
          ensure:   :present,
        )
      end

      before(:each) do
        allow(provider).to receive(:exists?).and_return(true)
        allow(provider1).to receive(:exists?).and_return(true)
      end

      it 'updates all values for quagga_logging file' do
        resource[:ensure] = :present
        provider.filename = '/tmp/file1.log'
        provider.level = :errors
        expect(provider).to receive(:vtysh).with([
                                        '-c', 'configure terminal',
                                        '-c', 'log file /tmp/file1.log errors',
                                        '-c', 'end',
                                        '-c', 'write memory'
                                      ])
        provider.flush
      end

      it 'updates facility value for quagga_logging syslog' do
        _resource = resource1
        provider1.filename = '/tmp/file1.log'
        provider1.level = :errors
        expect(provider1).to receive(:vtysh).with([
                                         '-c', 'configure terminal',
                                         '-c', 'log syslog errors',
                                         '-c', 'end',
                                         '-c', 'write memory'
                                       ])
        provider1.flush
      end
    end
  end
end
