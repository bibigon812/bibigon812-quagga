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
# @param frr_mode_enable
#   Indicates whether this is a quagga or FRRouting based system
# @param pim
#   Hash containing all of the pim daemon configuration directives
# @param ospf
#   Hash containing all of the ospf daemon configuration directives
# @param bgp
#   Hash containing all of the bgp daemon configuration directives
# @param zebra
#   Hash containing all of the zebra daemon configuration directives
class quagga (
  String $default_owner,
  String $default_group,
  String $default_mode,
  String $default_content,
  String $service_file,
  Boolean $service_file_manage,
  Hash $packages,
  Quagga::Pim $pim_settings,
  Quagga::Ospf $ospf_settings,
  Quagga::Bgp $bgp_settings,
  Quagga::Zebra $zebra_settings,
  Stdlib::AbsolutePath $config_dir = '/etc/quagga',
  Boolean $frr_mode_enable         = false,
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

  if $frr_mode_enable {
    $pim_params = $pim_settings + {
      'service_name' => 'frr',
    }
    $ospf_params = $ospf_settings + {
      'service_name' => 'frr',
    }
    $bgp_params = $bgp_settings + {
      'service_name' => 'frr',
    }
    $zebra_params = $zebra_settings + {
      'service_name' => 'frr',
    }
  } else {
    $pim_params = $pim_settings
    $ospf_params = $ospf_settings
    $bgp_params = $bgp_settings
    $zebra_params = $zebra_settings
  }

  # Child class inclusions
  class { 'quagga::pim':
    * => $pim_params,
  }
  contain quagga::pim
  class { 'quagga::ospf':
    * => $ospf_params,
  }
  contain quagga::ospf
  class { 'quagga::bgp':
    * => $bgp_params,
  }
  contain quagga::bgp
  class { 'quagga::zebra':
    * => $zebra_params,
  }
  contain quagga::zebra

  if $service_file_manage {
    if $frr_mode_enable {
      $frr_daemons_config = {
        'bgpd_enable' => $quagga::bgp::service_enable,
        'ospfd_enable' => $quagga::ospf::service_enable,
        'pimd_enable' => $quagga::pim::service_enable,
      }
      file { "${config_dir}/daemons":
        ensure  => 'file',
        owner   => $default_owner,
        group   => $default_group,
        mode    => '0750',
        replace => true,
        content => epp('quagga/frr.daemons.epp', $frr_daemons_config),
      }
      service { 'frr':
        ensure    => 'running',
        enable    => true,
        subscribe => Package[keys($quagga::packages)],
      }
    } else {
      file { $service_file:
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        replace => true,
        content => epp('quagga/quagga.sysconfig.epp'),
      }
    }
  }
}
