require 'spec_helper'

describe 'quagga' do
  it { is_expected.to compile.with_all_deps }

  it { is_expected.to contain_package('quagga') }

  it { is_expected.to contain_service('zebra') }
  it { is_expected.to contain_service('bgpd') }
  it { is_expected.to contain_service('ospfd') }

  it do
    is_expected.to contain_file('/etc/sysconfig/quagga').with_content('BABELD_OPTS="-P 0"
BGPD_OPTS="-P 0"
ISISD_OPTS="-P 0"
OSPF6D_OPTS="-P 0"
OSPFD_OPTS="-P 0"
RIPD_OPTS="-P 0"
RIPNGD_OPTS="-P 0"
ZEBRA_OPTS="-P 0"
')
  end

  it { is_expected.to contain_file('/etc/quagga/zebra.conf').with_owner('quagga').with_group('quagga').with_mode('0600') }
  it { is_expected.to contain_file('/etc/quagga/bgpd.conf').with_owner('quagga').with_group('quagga').with_mode('0600') }
  it { is_expected.to contain_file('/etc/quagga/ospfd.conf').with_owner('quagga').with_group('quagga').with_mode('0600') }
end
