# @param agentx
#   Manage SNMP agentx processes for the main quagga zebra process
#
# @param hostname
#   Router's hostname
#
# @param global_opts
#   Global options for all daemons
#
# @param interfaces
#   Global network interface parameters
#
# @param prefix_lists
#   Create prefix lists
#
# @param route_maps
#   Create route-map entries
#
# @param routes
#   Define static routes
#
# @param access_lists
#   Define access lists to use elsewhere in quagga config
#
# @param config_file
#   The main configuration file name
#
# @param config_file_manage
#   Manage the content of the configuration file
#
# @param service_name the main zebra service name
# @param service_enable enable the service
# @param service_manage manage the service state
# @param service_ensure manage the actual service state of stopped or running
# @param service_opts service startup options
type Quagga::Zebra = Struct[
  agentx             => Boolean,
  config_file_manage => Boolean,
  service_name       => String,
  service_enable     => Boolean,
  service_manage     => Boolean,
  service_ensure     => Enum['running', 'stopped'],
  service_opts       => String,
  hostname           => Stdlib::Host,
  global_opts        => Hash,
  interfaces         => Hash,
  prefix_lists       => Hash,
  route_maps         => Hash,
  routes             => Hash,
  access_lists       => Hash,
]
