class quagga (
  Boolean $enable         = true,
  String  $owner          = $::quagga::params::owner,
  String  $group          = $::quagga::params::group,
  String  $mode           = $::quagga::params::mode,
  String  $package_name   = $::quagga::params::package_name,
  String  $package_ensure = $::quagga::params::package_ensure,
  String  $content        = $::quagga::params::content,
) inherits ::quagga::params {

  $running = $enable

  package { 'quagga':
    ensure => present,
    name   => $package_name,
    before => Service['zebra', 'bgpd', 'ospfd', 'pimd']
  }

  file { '/etc/sysconfig/quagga':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => file('quagga/quagga'),
    require => Package['quagga'],
    notify  => Service['zebra', 'bgpd', 'ospfd', 'pimd'],
  }

  file {[
    '/etc/quagga/zebra.conf',
    '/etc/quagga/bgpd.conf',
    '/etc/quagga/ospfd.conf',
    '/etc/quagga/pimd.conf'
  ]:
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => $content,
    replace => 'no',
    require => Package['quagga'],
  }

  service { 'zebra':
    ensure  => $running,
    enable  => $enable,
    require => [
      File['/etc/quagga/zebra.conf'],
      Package['quagga'],
    ],
  }

  service { 'bgpd':
    ensure  => $running,
    enable  => $enable,
    require => [
      File['/etc/quagga/bgpd.conf'],
      Package['quagga'],
    ],
  }

  service { 'ospfd':
    ensure  => $running,
    enable  => $enable,
    require => [
      File['/etc/quagga/ospfd.conf'],
      Package['quagga'],
    ],
  }

  service { 'pimd':
    ensure  => $running,
    enable  => $enable,
    require => [
      File['/etc/quagga/pimd.conf'],
      Package['quagga'],
    ],
  }
}
