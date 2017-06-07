class quagga (
  Boolean $bgp            = true,
  Boolean $ospf           = true,
  Boolean $pim            = true,
  Boolean $zebra          = true,
  String  $owner          = $::quagga::params::owner,
  String  $group          = $::quagga::params::group,
  String  $mode           = $::quagga::params::mode,
  String  $package_name   = $::quagga::params::package_name,
  String  $package_ensure = $::quagga::params::package_ensure,
  String  $content        = $::quagga::params::content,

) inherits ::quagga::params {
  package { 'quagga':
    ensure => $package_ensure,
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
    ensure  => $zebra,
    enable  => $zebra,
    require => [
      File['/etc/quagga/zebra.conf'],
      Package['quagga'],
    ],
  }

  service { 'bgpd':
    ensure  => $bgp,
    enable  => $bgp,
    require => [
      File['/etc/quagga/bgpd.conf'],
      Package['quagga'],
    ],
  }

  service { 'ospfd':
    ensure  => $ospf,
    enable  => $ospf,
    require => [
      File['/etc/quagga/ospfd.conf'],
      Package['quagga'],
    ],
  }

  service { 'pimd':
    ensure  => $pim,
    enable  => $pim,
    require => [
      File['/etc/quagga/pimd.conf'],
      Package['quagga'],
    ],
  }
}
