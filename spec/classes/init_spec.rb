require 'spec_helper'

describe 'quagga' do
  let(:hiera_config) { 'spec/hieradata/hiera.yaml' }
  let(:title) { 'quagga' }
  let(:facts) {
    {
      :networking => {
        :fqdn => 'router-1.sandbox.local'
      }
    }
  }
  let(:environment) { 'production' }

  it { is_expected.to compile }
  it { is_expected.to compile.with_all_deps }

  it { is_expected.to contain_package('quagga') }

  it { is_expected.to contain_service('zebra') }
  it { is_expected.to contain_service('bgpd') }
  it { is_expected.to contain_service('ospfd') }
  it { is_expected.to contain_service('pimd') }

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

  it { is_expected.to contain_file('/etc/quagga/zebra.conf').with_owner('quagga').with_group('quagga').with_mode('0600') }
  it { is_expected.to contain_file('/etc/quagga/bgpd.conf').with_owner('quagga').with_group('quagga').with_mode('0600') }
  it { is_expected.to contain_file('/etc/quagga/ospfd.conf').with_owner('quagga').with_group('quagga').with_mode('0600') }
  it { is_expected.to contain_file('/etc/quagga/pimd.conf').with_owner('quagga').with_group('quagga').with_mode('0600') }
end
