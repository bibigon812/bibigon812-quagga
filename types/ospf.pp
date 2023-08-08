# @param agentx
#   Manage the AgentX integration
#
# @param config_file
#   configuration file of the OSPF service.
#
# @param config_file_manage
#   Manage the configuration file content
#
# @param service_ensure
#   Controls whether the service is stopped or running.
#
# @param service_name
#   the name of the OSPF service
#
# @param service_enable
#   Enable the OSPF service
#
# @param service_manage
#   Enable management of the OSPF service
#
# @param service_opts
#   Service start options
#
# @param router
#   OSPF router options.
# @see quagga_ospf_router
#
# @param areas
#   OSPF area options.
# @see quagga_ospf_area
#
# @param interfaces
#    OSPF parameters of interfaces.
# @see quagga_ospf_interface
#
type Quagga::Ospf = Struct[
  agentx             => Boolean,
  config_file_manage => Boolean,
  service_name       => String,
  service_enable     => Boolean,
  service_manage     => Boolean,
  service_ensure     => Enum['running', 'stopped'],
  service_opts       => String,
  router             => Quagga::OspfRouter,
  interfaces         => Hash,
  areas              => Hash,
]
