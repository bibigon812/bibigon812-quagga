class quagga::bgp (
  String $config_file,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Boolean $service_manage,
  Enum["running", "stopped"] $service_ensure,
  String $service_opts,
  Integer $as_number,
  Hash $router,
  Hash $peers,
  Hash $as_paths,
  Hash $community_lists,
  Hash $address_families
) {
  include quagga::bgp::config
  include quagga::bgp::service

  # Quagga only supports a single router instance
  if size($router) > 1 {
    fail("Quagga only supports a single BGP router instance in ${title}")
  }

  quagga_bgp {$as_number:
    * => $router
  }

  $peers.each |String $peer_name, Hash $peer| {
    quagga_bgp_peer {"$as_number $peer_name":
      * => $peer
    }
  }

  $as_paths.each |String $as_path_name, Hash $as_path| {
    quagga_bgp_as_path {$as_path_name:
      * => $as_path
    }
  }

  $community_lists.each |String $community_list_name, Hash $community_list| {
    quagga_bgp_community_list {$community_list_name:
      * => $community_list
    }
  }

  $address_families.each |String $address_family_name, Hash $address_family| {
    quagga_bgp_address_family {"$as_number $address_family_name":
      * => $address_family
    }
  }
}
