Puppet::Type.newtype(:ospf) do
  @doc = %q{This type provides the capabilites to manage ospf router within
    puppet.

    Example:

    ospf { 'ospf':
      ensure              => present,
      abr_type            => cisco,
      default_information => {
        originate   => true,
        always      => true,
        metric      => 100,
        metric_type => 2,
        route_map   => ROUTE_MAP,
      },
      area                => {
        0.0.0.0 => {
          network => [
            10.0.0.0/24,
            192.168.0.0/24,
          ],
          ...
        },
        0.0.0.1 => {
          network => [
            10.0.10.0/24,
          ],
        },
      },
      redistribute        => {
        ...
      },
      router_id           => 192.168.0.1,
    }
  }

  class String
    def is_number?
      true if Float(self) rescue false
    end
  end

  ensurable

  newparam(:name) do
    desc %q{Name must be 'ospf'.}
    newvalues(:ospf)
  end

  newproperty(:abr_type, :required_feature => :abr_type) do
    desc %q{Set OSPF ABR type.}

    newvalues(:cisco, :ibm, :shortcut, :standard)
    defaultto(:cisco)
  end


  newproperty(:default_information) do
    desc %q{Control distribution of default information.}

    keys = [ :originate, :always, :metric, :metric_type, :route_map ]

    defaultto(:originate => :false)

    validate do |value|
      case value
      when Hash
        value.each do |key, value|
          unless keys.include?(key.to_s.gsub(/-/, '_').to_sym)
            raise ArgumentError, '\'%s\' is not a valid originate attribute' % key
          end
          case key
          when :originate, 'originate', :always, 'always'
            unless [ :false, :true ].include?(value.to_s.to_sym)
              raise ArgumentError, '\'%s\' is not a boolean value' % value
            end
          when 'metric-type', 'metric_type', :metric_type
            unless value.to_s.is_number? and [1, 2].include?(value.to_s.to_i)
              raise ArgumentError, 'Value of metric-type must be 1 or 2 but not %s' % value
            end
          when 'metric', :metric
            unless value.to_s.is_number? and value.to_s.to_i >= 0 and value.to_s.to_i <= 16777214
              raise ArgumentError, 'Value of metric must be between 0 and 16777214 but not %s' % value
            end
          end
        end
      else
        raise ArgumentError, 'This property should be a Hash' % value
      end
    end

    munge do |value|
      hash = {}
      value.each do |key, value|
        case key
        when :originate, 'originate', :always, 'always'
          hash[key.to_s.gsub(/-/, '_').to_sym] = value.to_s.to_sym
        when 'metric-type', 'metric_type', :metric_type, 'metric', :metric
          hash[key.to_s.gsub(/-/, '_').to_sym] = value.to_s.to_i
        else
          hash[key.to_s.gsub(/-/, '_').to_sym] = value
        end
      end
      hash
    end
  end


  newproperty(:area) do
    desc %q{Enable routing on an IP network.}

    keys = [ :network ]

    validate do |value|
      case value
      when Hash
        value.each do |key, value|
          unless key =~ /\A\d+\.\d+\.\d+\.\d+\Z/
            raise ArgumentError, '\'%s\' is not a valid area' % key
          end
          value.each do |key, value|
            if keys.include?(key.to_sym)
              case value
              when Array
                value.each do |value|
                  unless value =~ /\A\d+\.\d+\.\d+\.\d+\/\d+\Z/
                    raise ArgumentError, '\'%s\' is not a valid network' % value
                  end
                end
              when String
                unless value =~ /\A\d+\.\d+\.\d+\.\d+\/\d+\Z/
                  raise ArgumentError, '\'%s\' is not a valid network' % value
                end
              else
                raise ArgumentError, '\'%s\' is not a valid network' % value
              end
            else
              raise ArgumentError, 'OSPF area does not contain this attribute: %s' % key
            end
          end
        end
      else
        raise ArgumentError, 'This property should be a Hash'
      end
    end

    munge do |value|
      hash = {}
      value.each do |area, value|
        hash[area] = {}
        value.each do |key, value|
          case key
          when 'network', :network
            case value
            when Array
              hash[area][:network] = value
            else
              hash[area][:network] ||= []
              hash[area][:network] << value
            end
          else
            hash[area][key] = value
          end
        end
      end
      hash
    end
  end

  newproperty(:redistribute) do

    desc %q{ Redistribute information from another routing protocol. }
    munge do |value|
      if value.is_a?(String)
        eval(value.gsub(/(\w+)/, '\'\1\''))
      else
        value
      end
    end
  end

  newproperty(:router_id, :required_feature => :router_id) do
    desc %q{ router-id for the OSPF process. }
    newvalues(/^[\d\.]+$/)
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
