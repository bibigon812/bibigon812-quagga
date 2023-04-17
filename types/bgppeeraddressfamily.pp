# @summary Address family specific settings for BGP peers
#
# @see quagga_bgp_peer_address_family
type Quagga::BgpPeerAddressFamily = Struct[
  Optional[peer_group]             => Variant[Boolean,String],
  Optional[activate]               => Boolean,
  Optional[allow_as_in]            => Boolean,
  Optional[default_originate]      => Boolean,
  Optional[next_hop_self]          => Boolean,
  Optional[prefix_list_in]         => String,
  Optional[prefix_list_out]        => String,
  Optional[route_map_export]       => String,
  Optional[route_map_import]       => String,
  Optional[route_map_in]           => String,
  Optional[route_map_out]          => String,
  Optional[route_reflector_client] => Boolean,
  Optional[route_server_client]    => Boolean,
]
