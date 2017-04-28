Puppet::Type.newtype(:as_path) do
  @doc = %q{ This type provides the capabilities to manage as-path access-list
    within puppet.

    Example:

    as_path { 'from_as100:1:permit:_100$': }
  }

  ensurable

  newparam(:name) do
    desc %q{ The name contains the as-path name, action and regex }

    newvalues(/\A\w+:\d+:(deny|permit):\^?[_\d\.\\\*\+\[\]\|\?]+\$?\Z/)
  end

  autorequire(:package) do
    case value(:provider)
      when :quagga
        %w{quagga}
      else
        []
    end
  end

  autorequire(:service) do
    case value(:provider)
      when :quagga
        %w{zebra ospfd}
      else
        []
    end
  end
end