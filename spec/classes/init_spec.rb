require 'spec_helper'

describe 'quagga' do
  let(:hiera_config) { 'spec/data/hiera.yaml' }
  let(:title) { 'quagga' }
  let(:facts) do
    {
      networking: {
        fqdn: 'router-1.sandbox.local',
        ip: '172.24.128.1',
      }
    }
  end
  let(:environment) { 'production' }

  it 'compiles' do
    is_expected.to compile.with_all_deps
  end

  it 'includes quagga packages' do
    is_expected.to contain_package('quagga')
  end

  it do
    is_expected.to contain_file('/etc/sysconfig/quagga').with_content('#
# Managed by Puppet in the production environment
#

BGPD_OPTS="-P 0"
OSPFD_OPTS="-P 0"
PIMD_OPTS="-P 0"
ZEBRA_OPTS="-P 0"
')
  end

  ['zebra', 'bgpd', 'ospfd', 'pimd'].each do |daemon_file|
    it "contains service #{daemon_file}" do
      is_expected.to contain_service(daemon_file)
    end
    it "creates file #{daemon_file}" do
      is_expected.to contain_file("/etc/quagga/#{daemon_file}.conf").with(
        owner: 'quagga',
        group: 'quagga',
        mode: '0600',
      )
    end
  end

  context 'frr mode is enabled' do
    let(:params) do
      {
        default_owner: 'frr',
        default_group: 'frr',
        frr_mode_enable: true,
        config_dir: '/etc/frr',
        packages: {
          'frr' => { ensure: 'latest' },
          'frr-pythontools' => { ensure: 'latest' },
        },
      }
    end

    it 'does not contain quagga sysconfig' do
      is_expected.not_to contain_file('/etc/sysconfig/quagga')
    end

    it 'configures the frr daemons' do
      is_expected.to contain_file('/etc/frr/daemons').with(
        ensure: 'file',
        owner: 'frr',
        group: 'frr',
        mode: '0750',
      )
      content = catalogue.resource('file', "#{params[:config_dir]}/daemons").send(:parameters)[:content]
      expect(content).to match(%r{^bgpd=yes$})
      expect(content).to match(%r{^pimd=yes$})
      expect(content).to match(%r{^ospfd=yes$})
    end

    it 'configures the frr service' do
      is_expected.to contain_service('frr').with(
        ensure: 'running',
        enable: true,
        subscribe: [
          'File[/etc/frr/daemons]',
          'Package[frr]',
          'Package[frr-pythontools]',
        ],
      )
    end
  end
end
