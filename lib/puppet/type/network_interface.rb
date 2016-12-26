Puppet::Type.newtype(:network_interface) do
  @doc = <<-EOS
    This type provides the capability to manage network interfaces within
    puppet.
  EOS

  ensurable

  newparam(:name, :namevar => true) do
    desc %q{ The frendly name of the network interface. }
  end

  newproperty(:type) do
    desc %q{ Type of the network interface.
      - 'ethernet'
      - 'bonding'
      - 'bridge'
    }
    newvalues(/\A([Ee][Tt][Hh][Ee][Rr][Nn][Ee][Tt]|[Bb][Oo][Nn][Dd][Ii][Nn][Gg]|[Bb][Rr][Ii][Dd][Gg][Ee])\Z/)

    munge do |value|
      value.downcase
    end
  end
end
