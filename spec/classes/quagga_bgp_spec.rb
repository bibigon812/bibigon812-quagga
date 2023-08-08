require 'spec_helper'
require 'deep_merge'

describe 'quagga::bgp' do
  let(:params) do
    {
      agentx: false,
      config_file_manage: true,
      service_name: 'bgpd',
      service_enable: false,
      service_manage: false,
      frr_mode_enable: true,
      service_ensure: 'running',
      service_opts: '-P 0',
      config_file: '/etc/frr/bgpd.conf',
      router: {},
      peers: {
        site_routers: {
          local_as: 11_000,
          remote_as: 10_000,
          passive: false,
          peer_group: true,
          shutdown: false,
          update_source: 'ens192',
          ebgp_multihop: 2,
          address_families: {
            ipv4_unicast: {
              activate: true,
              default_originate: false,
            },
          },
        },
      },
      as_paths: {},
      community_lists: {},
      address_families: {},
    }
  end

  it 'compiles without error' do
    is_expected.to compile.with_all_deps
  end
end
