Puppet::Type.newtype(:as_path) do
  @doc = %q{
  This type provides the capabilities to manage as-path access-list within puppet.

    Examples:

      as_path { 'as100':
          ensure => present,
          rules => [
              { permit => '_100$', },
              { permit => '_100_', },
          ],
      }
  }

  ensurable

  newparam(:name) do
    desc %q{ The name of the as-path access-list. }

    newvalues(/\A\w+\Z/)
  end

  newproperty(:rules, :array_matching => :all) do
    desc %q{ Rules of the as-path access-list. `{ action => regex }`. }

    validate do |value|
      case value
        when Hash
          value.each do |action, regex|
            unless [:deny, :permit].include?(action.to_s.to_sym)
              raise(ArgumentError, "Use the action permit or deny instead of #{action}")
            end
            unless regex.match(/\A\^?[_\d\.\\\*\+\[\]\|\?]+\$?\Z/)
              raise(ArgumentError, "The regex #{regex} is invalid")
            end
          end
        else
          raise(ArgumentError, 'Use a hash { action => regex }')
      end
    end

    munge do |value|
      new_value = {}
      value.each do |action, regex|
        new_value[action.to_s.to_sym] = regex
      end
      new_value
    end

    def should_to_s(value)
      value.inspect
    end
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