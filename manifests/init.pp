# @summary Manages common option of quagga services
# @api public
# @param default_owner
#   Specifies the default owner of quagga files.
# @param default_group
#   Specifies the default group of quagga files.
# @param default_mode
#   Specifies the default mode of quagga files.
# @param default_content
#   Specifies the default content of quagga files.
# @param service_file
#   The system configuration file on the filesyustem
# @param service_file_manage
#   Enable or disable management of the system configuration file
# @param packages
#   Specifies which packages will be installed
# @param config_dir
#   Directory in which the quagga configuration files reside
class quagga (
  String $default_owner,
  String $default_group,
  String $default_mode,
  String $default_content,
  String $service_file,
  Boolean $service_file_manage,
  Hash $packages,
  Stdlib::AbsolutePath $config_dir = '/etc/quagga',
) {
  $packages.each |String $package_name, Hash $package| {
    package { $package_name:
      * => $package,
    }
  }

  File {
    owner   => $default_owner,
    group   => $default_group,
    mode    => $default_mode,
    content => $default_content,
    replace => false,
    ensure  => present,
    require => Package[keys($packages)],
  }

  contain quagga::logging
  contain quagga::zebra
  contain quagga::bgp
  contain quagga::ospf
  contain quagga::pim

  if $service_file_manage {
    file { $service_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      replace => true,
      content => epp('quagga/quagga.sysconfig.epp'),
    }
  }
}
