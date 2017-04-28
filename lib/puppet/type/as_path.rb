Puppet::Type.newtype(:as_path) do
  @doc = %q{This type provides the capabilities to manage as-path access-list
    within puppet.

    Example:

    as_path { 'from_as100:1':
      ensure => present,
      action => 'permit',
      regex  => '_100$',
    }
  }

  ensurable

  newparam(:name) do
    desc %q{ The name contains the as-path name and sequence number }

    newvalues(/\A\w+:\d+\Z/)
  end

  newproperty(:action) do
    desc %q{ Action permit or deny }

    defaultto(:permit)
    newvalues(:deny, :permit)
  end

  newproperty(:regex) do
    desc %q{ A regular-expression to match the BGP AS paths }

    newvalues(/\A[_\^\\]?[_\d\.\\\*\+\[\]\|\?]+[_\$\\]?\Z/)
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

  autorequire(:as_path) do
    as_paths = []
    name, sequence = value(:name).split(/:/)

    (1...sequence).each do |seq|
      as_paths << "#{name}:#{seq}"
    end

    as_paths
  end
end