# @summary manage a Quagga prefix list
#
# @param rules Prefix list definition
#
# @see quagga_prefix_list
define quagga::prefix_list (
  Hash $rules = {},
) {
  $rules.reduce({}) |Hash $rules, Tuple[Integer, Hash] $rule| {
    merge($rules, { "${name} ${rule[0]}" => $rule[1] })
  }.each |String $prefix_list_name, Hash $prefix_list| {
    quagga_prefix_list { $prefix_list_name:
      * => $prefix_list,
    }
  }
}
