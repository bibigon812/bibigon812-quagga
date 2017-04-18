Puppet::Type.newtype(:ospf_area) do
  @doc = %q{ OSPF area parameters

    Example:

      ospf_area { '0.0.0.0':
        default_cost => 10,
        export_list => ABCD,
        filter_prefix => ABCD,
        import_list => ABCD,
        range => [
          '10.0.0.0/24 not-advertise',
          '192.168.0.0/24 not-advertise',
        ],
        shortcut => default,
      }

      ospf_area { '0.0.0.1':
        stub => true,
      }

      ospf_area { '0.0.0.2':
        stub => no-summary,
        virtual_link => [
          '1.1.1.1 hello-interval 2',
        ],
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
