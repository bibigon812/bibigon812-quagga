# @param agentx manage the SNMP agentx for PIM
# @param config_file_manage enable management of the PIM service setting file.
# @param service_name the name of the PIM service.
# @param service_enable  enable the PIM service.
# @param service_manage enable management of the PIM service.
# @param service_ensure the state of the PIM Service.
# @param service_opts service start options.
# @param router PIM router options. See the type [`quagga_pim_router`](#quagga_pim_router).
# @param interfaces OSPF parameters of interfaces. See the type [`quagga_pim_interface`](#quagga_pim_interface).
type Quagga::Pim = Struct[
  agentx             => Boolean,
  config_file_manage => Boolean,
  service_name       => String,
  service_enable     => Boolean,
  service_manage     => Boolean,
  service_ensure     => Enum['running', 'stopped'],
  service_opts       => String,
  router             => Hash,
  interfaces         => Hash,
]
