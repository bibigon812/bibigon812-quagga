define quagga::bgp::peer (
  Variant[Enum["absent"], Integer[1, 4294967295]] $local_as,
  Variant[Enum["absent"], Integer[1, 4294967295]] $remote_as,
  Boolean $passive,
  Optional[Variant[Boolean, String]] $peer_group = undef,
  Boolean $shutdown = false,
  Optional[String] $update_source = undef,
  Hash $address_families = {},
  Enum["present", "absent"] $ensure = "present"
) {
  unless defined(Class["quagga::bgp"]) {
    fail("You must include the quagga::bgp base class before using any quagga::bgp defined resources")
  }

  quagga_bgp_peer {$name:
    local_as => $local_as,
    remote_as => $remote_as,
    passive => $passive,
    peer_group => $peer_group,
    shutdown => $shutdown,
    update_source => $update_source,
    ensure => $ensure
  }

  $address_families.each |String $address_family_name, Hash $address_family| {
    quagga_bgp_peer_address_family {$address_family_name:
      peer_group => $name,
      * => $address_family,
      require => Quagga_bgp_peer[$name]
    }
  }
}
