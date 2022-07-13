class quagga::bgp (
  Boolean $agentx,
  String $config_file,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Boolean $service_manage,
  Enum['running', 'stopped'] $service_ensure,
  String $service_opts,
  Hash $router,
  Hash $peers,
  Hash $as_paths,
  Hash $community_lists,
  Hash $address_families,
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
