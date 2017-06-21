class quagga (
  String  $owner          = $::quagga::params::owner,
  String  $group          = $::quagga::params::group,
  String  $mode           = $::quagga::params::mode,
  String  $package_name   = $::quagga::params::package_name,
  String  $package_ensure = $::quagga::params::package_ensure,
  String  $content        = $::quagga::params::content,
  Hash    $as_paths        = {},
  Hash    $bgps            = {},
  Hash    $community_lists = {},
  Hash    $interfaces      = {},
  Hash    $ospf            = {},
  Hash    $prefix_lists    = {},
  Hash    $route_maps      = {},

) inherits ::quagga::params {

  $real_route_maps = deep_merge($route_maps, hiera_hash('quagga::route_maps', {}))

  class { '::quagga::route_maps':
    settings => $real_route_maps,
  }

  package { 'quagga':
    ensure => $package_ensure,
    name   => $package_name,
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
    ensure  => true,
    enable  => true,
    require => [
      File['/etc/sysconfig/quagga', '/etc/quagga/zebra.conf'],
      Package['quagga'],
    ],
  }

  service { 'bgpd':
    ensure  => true,
    enable  => true,
    require => [
      File['/etc/sysconfig/quagga', '/etc/quagga/bgpd.conf'],
      Package['quagga'],
    ],
  }

  service { 'ospfd':
    ensure  => true,
    enable  => true,
    require => [
      File['/etc/sysconfig/quagga', '/etc/quagga/ospfd.conf'],
      Package['quagga'],
    ],
  }

  service { 'pimd':
    ensure  => true,
    enable  => true,
    require => [
      File['/etc/sysconfig/quagga', '/etc/quagga/pimd.conf',],
      Package['quagga'],
    ],
  }
}
