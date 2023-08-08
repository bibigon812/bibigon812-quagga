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
type Quagga::Bgp = Struct[
  agentx             => Boolean,
  config_file_manage => Boolean,
  service_name       => String,
  service_enable     => Boolean,
  service_manage     => Boolean,
  service_ensure     => Enum['running', 'stopped'],
  service_opts       => String,
  router             => Hash,
  peers              => Hash,
  as_paths           => Hash,
  community_lists    => Hash,
  address_families   => Hash,
]
