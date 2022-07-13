define quagga::route_map (
  Hash $rules = {},
) {
  $rules.reduce( {}) |Hash $rules, Tuple[Integer, Hash] $rule| {
    merge($rules, { "${name} ${rule[0]}" => $rule[1] })
  }.each |String $route_map_name, Hash $route_map| {
    quagga_route_map { $route_map_name:
      * => $route_map,
    }
  }
}
