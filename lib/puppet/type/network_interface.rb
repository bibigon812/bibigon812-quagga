Puppet::Type.newtype(:network_interface) do
  @doc = %q{This type provides the capability to manage network interfaces
    within puppet.}

  ensurable do
    desc %q{Manage the state of this rule. The default action is *up*.}

    newvalues(:up) do
      provider.up
    end

    newvalues(:down) do
      provider.down
    end

    newvalues(:absent) do
      provider.destroy
    end

    defaultto(:up)
  end

  newparam(:name, :namevar => true) do
    desc %q{The frendly name of the network interface.}
  end

  newproperty(:type) do
    desc %q{Type of the network interface:
      - ethernet
      - bonding
      - bridge
    }

    newvalues(:bonding)
    newvalues(:bridge)
    newvalues(:ethernet)

    defaultto(:ethernet)
  end
end
