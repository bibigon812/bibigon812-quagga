class quagga (
  String $default_owner,
  String $default_group,
  String $default_mode,
  String $default_content,
  String $service_file,
  Boolean $service_file_manage,
  Hash $packages,
) {
  $packages.each |String $package_name, Hash $package| {
    package {$package_name:
      * => $package
    }
  }

  File {
    owner   => $default_owner,
    group   => $default_group,
    mode    => $default_mode,
    content => $default_content,
    replace => false,
    ensure  => present,
    require => Package[keys($packages)]
  }

  contain quagga::zebra
  contain quagga::bgp
  contain quagga::ospf
  contain quagga::pim

  if $service_file_manage {
    file {$service_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      replace => true,
      content => epp('quagga/quagga.sysconfig.epp')
    }
  }
}
