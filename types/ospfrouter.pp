type Quagga::OspfRouter = Struct[
  router_id                       => Stdlib::IP::Address::V4,
  Optional[abr_type]              => Enum['cisco','ibm','shortcut','standard'],
  Optional[default_originate]     => Boolean,
  Optional[opaque]                => Boolean,
  Optional[redistribute]          => Array[String],
  Optional[rfc1583]               => Boolean,
  Optional[log_adjacency_changes] => Boolean,
  Optional[passive_interfaces]    => Array[String],
  Optional[distribute_list]       => Array[String],
]
