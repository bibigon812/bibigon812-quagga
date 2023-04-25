# @summary Manage the Quagga BGP Daemon
#
# This class is automatically included when you include the main quagga class.
# However, it has a number of parameters that can be set via hiera.
#
# @param agentx
#   Enable SNMP integration
#
# @param config_file
#   Path to the quagga configuration file for BGP
#
# @param config_file_manage
#
#   If true, manage the existence of the `$config_file`
#
# @param service_name
#   System service name for quagga bgpd
#
# @param service_enable
#   Manages the state of the service at boot
#
# @param service_manage
#   If true, manages the state of the BGP daemon and the SNMP agentx
#
# @param service_ensure
#   Ensures the service is either stopped or running.
#
# @param service_opts
#   Options for the BGP service
#
# @param router
#   Parameters for the router process.
# @see quagga_bgp_router
#
# @param peers
#   BGP Peers.
# @see quagga::bgp::peer
#
# @param as_paths
#   AS Path rules.
# @see quagga_bgp_as_path
#
# @param community_lists
#   BGP Community list options.
# @see quagga_bgp_community_list
#
# @param address_families
#   BGP Address family options.
# @see quagga_bgp_address_family
class quagga::bgp (
  Boolean $agentx,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Boolean $service_manage,
  Boolean $frr_mode_enable,
  Enum['running', 'stopped'] $service_ensure,
  String $service_opts,
  Hash $router,
  Hash $peers,
  Hash $as_paths,
  Hash $community_lists,
  Hash $address_families,
  Stdlib::Unixpath $config_file               = "${quagga::config_dir}/bgpd.conf",
) {
  include quagga::bgp::config
  include quagga::bgp::service

  if $service_enable and $service_ensure == 'running' {
    $agentx_ensure = $agentx ? {
      true  => 'present',
      false => 'absent'
    }

    file_line { 'bgp_agentx':
      ensure => $agentx_ensure,
      path   => $config_file,
      line   => 'agentx',
    }

    if $service_manage {
      File_line['bgp_agentx'] {
        notify => Service[$service_name]
      }
    }

    quagga_bgp_router { 'bgp':
      * => $router,
    }

    $peers.each |String $peer_name, Hash $peer| {
      quagga::bgp::peer { $peer_name:
        * => $peer,
      }
    }

    $as_paths.each |String $as_path_name, Hash $as_path| {
      quagga_bgp_as_path { $as_path_name:
        * => $as_path,
      }
    }

    $community_lists.each |Integer $community_list_name, Hash $community_list| {
      quagga_bgp_community_list { sprintf('%d', $community_list_name):
        * => $community_list,
      }
    }

    $address_families.each |String $address_family_name, Hash $address_family| {
      quagga_bgp_address_family { $address_family_name:
        * => $address_family,
      }
    }
  }
}
