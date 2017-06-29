class quagga::bgp (
  String $config_file,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Boolean $service_manage,
  Enum["running", "stopped"] $service_ensure,
  String $service_opts,
  Hash $router,
  Hash $peers,
  Hash $route_maps,
  Hash $as_paths,
  Hash $community_lists
) {
  include quagga::bgp::config
  include quagga::bgp::service

  # Quagga only supports a single router instance
  if size($router) > 1 {
    fail("Quagga only supports a single BGP router instance in ${title}")
  }

  $router.each |String $router_name, Hash $router| {
    quagga_bgp {$router_name:
      * => $router
    }
  }

  $peers.each |String $peer_name, Hash $peer| {
    quagga_bgp_peer {$peer_name:
      * => $peer
    }
  }

  $route_maps.each |String $route_map_name, Hash $route_map| {
    quagga_route_map {$route_map_name:
      * => $route_map
    }
  }

  $as_paths.each |String $as_path_name, Hash $as_path| {
    quagga_as_path {$as_path_name:
      * => $as_path
    }
  }

  $community_lists.each |String $community_list_name, Hash $community_list| {
    quagga_community_list {$community_list_name:
      * => $community_list
    }
  }
}
