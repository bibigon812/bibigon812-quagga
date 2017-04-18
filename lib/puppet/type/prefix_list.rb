Puppet::Type.newtype(:prefix_list) do
  @doc = %q{
    Example:

      prefix_list { 'ABCD':
        description => 'Prefix-list description',
        seq => {
          5 => {
            action => permit,
            prefix => 10.0.0.0/24,
            le => 32,
            ge => 25,
          }
        },
      }
  }

  ensurable

  newparam(:name) do
    desc %q{ Prefix-list name }
    newvalues /\A[\w-]+\Z/
  end

  newproperty(:description) do
    desc %q{ Up to 80 characters describing this prefix-list }

    newvalues /\A[\w\s-]{,80}\Z/
  end

  newproperty(:seq) do
    desc %{ Sequence number of entry }

    validate do |value|
      unless value.is_a?(Hash)
        raise ArgumentError, 'Sequence should be a Hash'
      end
    end
  end
end
