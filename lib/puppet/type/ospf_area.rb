Puppet::Type.newtype(:ospf_area) do
  @doc = %q{ OSPF area parameters

    Example:

      ospf_area { '0.0.0.0':
        default_cost  => 10,
        export_list   => ABCD,
        filter_prefix => ABCD,
        import_list   => ABCD,
        network       => [ 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 ],
        shortcut      => default,
      }

      ospf_area { '0.0.0.1':
        stub => true,
      }

      ospf_area { '0.0.0.2':
        stub => no-summary,
      }
  }

  ensurable

  newparam(:name) do
    desc %q{ OSPF area }
    newvalues /\A\d+\.\d+\.\d+\.\d+\Z/
  end

  # TODO
  #
end
