class quagga (
  String  $owner          = $::quagga::params::owner,
  String  $group          = $::quagga::params::group,
  String  $mode           = $::quagga::params::mode,
  String  $package_name   = $::quagga::params::package_name,
  String  $package_ensure = $::quagga::params::package_ensure,
  String  $content        = $::quagga::params::content,
  Hash    $as_paths        = {},
  Hash    $bgp             = {},
  Hash    $community_lists = {},
  Hash    $global          = {},
  Hash    $interfaces      = {},
  Hash    $ospf            = {},
  Hash    $prefix_lists    = {},
  Hash    $route_maps      = {},

) inherits ::quagga::params {

  # Stubs for CentOS
  $quagga_system_config = '/etc/sysconfig/quagga'
  $bgp_config = '/etc/quagga/bgpd.conf'
  $ospf_config = '/etc/quagga/ospfd.conf'
  $pim_config = '/etc/quagga/pimd.conf'
  $zebra_config = '/etc/quagga/zebra.conf'

  $services = {
    'bgpd' => {
      'ensure' => true,
      'enable' => true,
      'require' => [
        File[$quagga_system_config, $bgp_config,],
        Package[$package_name,],
      ],
    },
    'ospfd' => {
      'ensure' => true,
      'enable' => true,
      'require' => [
        File[$quagga_system_config, $ospf_config,],
        Package[$package_name,],
      ],
    },
    'pimd' => {
      'ensure' => true,
      'enable' => true,
      'require' => [
        File[$quagga_system_config, $pim_config,],
        Package[$package_name,],
      ],
    },
    'zebra' => {
      'ensure' => true,
      'enable' => true,
      'require' => [
        File[$quagga_system_config, $zebra_config,],
        Package[$package_name,],
      ],
    },
  }

  $real_interfaces = deep_merge($interfaces, hiera_hash('quagga::interfaces', {}))
  unless empty($real_interfaces) {
    $needed_services = $real_interfaces.reduce([]) |$memo, $value| {
      union($memo, $value[1].reduce([]) |$memo, $value| {
        if $value[0] =~ /pim/ {
          union($memo, ['pimd'])
        } elsif $value[0] =~ /^ospf/ {
          union($memo, ['ospfd'])
        } else {
          union($memo, ['zebra'])
        }
      })
    }

    $needed_services.each |$service| {
      ensure_resource('service', $service, $services[$service])
    }

    class { '::quagga::interfaces':
      settings => $real_interfaces,
    }
  }

  $real_bgp = deep_merge($bgp, hiera_hash('quagga::bgp', {}))
  unless empty($real_bgp) {
    ['bgpd', 'zebra'].each |$service| {
      ensure_resource('service', $service, $services[$service])
    }

    class { '::quagga::bgp':
      settings => $real_bgp,
    }
  }

  $real_ospf = deep_merge($ospf, hiera_hash('quagga::ospf', {}))
  unless empty($real_ospf) {
    ['ospfd', 'zebra'].each |$service| {
      ensure_resource('service', $service, $services[$service])
    }

    class { '::quagga::ospf':
      settings => $real_ospf,
    }
  }

  $real_route_maps = deep_merge($route_maps, hiera_hash('quagga::route_maps', {}))
  unless empty($real_route_maps) {
    ['bgpd', 'zebra'].each |$service| {
      ensure_resource('service', $service, $services[$service])
    }

    class { '::quagga::route_maps':
      settings => $real_route_maps,
    }
  }

  $real_as_paths = deep_merge($as_paths, hiera_hash('quagga::as_paths', {}))
  unless empty($real_as_paths) {
    ['bgpd', 'zebra'].each |$service| {
      ensure_resource('service', $service, $services[$service])
    }

    class { '::quagga::as_paths':
      settings => $real_as_paths,
    }
  }

  $real_community_lists = deep_merge($community_lists, hiera_hash('quagga::community_lists', {}))
  unless empty($real_community_lists) {
    ['bgpd', 'zebra'].each |$service| {
      ensure_resource('service', $service, $services[$service])
    }

    class { '::quagga::community_lists':
      settings => $real_community_lists,
    }
  }

  $real_prefix_lists = deep_merge($prefix_lists, hiera_hash('quagga::prefix_lists', {}))
  unless empty($real_prefix_lists) {
    ensure_resource('service', 'zebra', $services['zebra'])
    class { '::quagga::prefix_lists':
      settings => $real_prefix_lists,
    }
  }

  $real_global = deep_merge($global, hiera_hash('quagga::global', {}))
  unless empty($real_global) {
    ensure_resource('service', 'zebra', $services['zebra'])
    class { '::quagga::global':
      settings => $real_global,
    }
  }

  package { 'quagga':
    ensure => $package_ensure,
    name   => $package_name,
  }

  file { $quagga_system_config:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => file('quagga/quagga'),
    require => Package[$package_name],
    # notify  => Service['zebra', 'bgpd', 'ospfd', 'pimd'],
  }

  file {[
    $bgp_config,
    $ospf_config,
    $pim_config,
    $zebra_config,
  ]:
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => $content,
    replace => 'no',
    require => Package[$package_name],
  }
}
