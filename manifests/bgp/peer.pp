# @summary wrapper for quagga_bgp_peer and quagga_bgp_peer_address_family
# @api private
define quagga::bgp::peer (
  Optional[Integer[1, 4294967295]] $local_as = undef,
  Optional[Integer[1, 4294967295]] $remote_as = undef,
  Boolean $passive = false,
  Optional[String] $password = undef,
  Optional[Variant[Boolean, String]] $peer_group = undef,
  Boolean $shutdown = false,
  Optional[String] $update_source = undef,
  Optional[Integer[1,255]] $ebgp_multihop = undef,
  Hash[String, Quagga::BgpPeerAddressFamily] $address_families = {},
  Enum['present', 'absent'] $ensure = 'present',
) {
  unless defined(Class['quagga::bgp']) {
    fail('You must include the quagga::bgp base class before using any quagga::bgp defined resources.')
  }

  quagga_bgp_peer { $name:
    ensure        => $ensure,
    local_as      => $local_as,
    remote_as     => $remote_as,
    passive       => $passive,
    password      => $password,
    peer_group    => $peer_group,
    shutdown      => $shutdown,
    update_source => $update_source,
    ebgp_multihop => $ebgp_multihop,
  }

  $address_families.each |String $address_family_name, Hash $address_family| {
    quagga_bgp_peer_address_family { "${name} ${address_family_name}":
      *       => $address_family,
      require => Quagga_bgp_peer[$name],
    }
  }
}
