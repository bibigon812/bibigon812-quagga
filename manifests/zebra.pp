class quagga::zebra (
  String $config_file,
  Boolean $config_file_manage,
  String $service_name,
  Boolean $service_enable,
  Boolean $service_manage,
  Enum['running', 'stopped'] $service_ensure,
  String $service_opts,
  Hash $routes,
  Hash $access_lists,
) {
  include quagga::zebra::config
  include quagga::zebra::service

  if $service_enable and $service_ensure == 'running' {
    $routes.each |String $route_title, Hash $route| {
      quagga_static_route { $route_title:
        * => $route,
      }
    }

    $access_lists.each |$access_list_name, Hash $access_list| {
      $list_name = $access_list_name ? {
        Integer => sprintf('%d', $access_list_name),
        default => $access_list_name,
      }

      quagga_access_list { $list_name:
        * => $access_list,
      }
    }
  }
}
