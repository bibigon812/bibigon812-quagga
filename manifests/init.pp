class quagga (
  Boolean $enable         = true,
  String  $owner          = $::quagga::params::owner,
  String  $group          = $::quagga::params::group,
  String  $mode           = $::quagga::params::mode,
  String  $package_name   = $::quagga::params::package_name,
  String  $package_ensure = $::quagga::params::package_ensure,
  String  $content        = $::quagga::params::content,
) inherits ::quagga::params {
  
  package { $package_name:
    ensure => present,
    before => Service['zebra', 'bgp', 'ospfd']
  }

  file { '/etc/sysconfig/quagga':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0644',
    content => file('quagga/quagga'),
    require => Package['quagga'],
    notify  => Service['quagga', 'bgp', 'ospfd'],
  }

  file { '/etc/quagga/zebra.conf':
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => $content,
    replace => 'no',
    require => Package[$package_name],
  }

  file { '/etc/quagga/bgpd.conf':
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    replace => 'no',
    require => Package[$package_name],
  }

  file { '/etc/quagga/ospfd.conf':
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    replace => 'no',
    require => Package[$package_name],
  }

  service { 'zebra':
    ensure  => running,
    enable  => true,
    require => [
      Package[$package_name],
      File['/etc/quagga/zebra.conf'],
    ],
  }

  service { 'bgpd':
    ensure  => running,
    enable  => true,
    require => [
      File['/etc/quagga/bgpd.conf'],
      Package[$package_name],
    ],
  }

  service { 'ospfd':
    ensure  => running,
    enable  => true,
    require => [
      File['/etc/quagga/ospfd.conf'],
      Package[$package_name],
    ],
  }
}
