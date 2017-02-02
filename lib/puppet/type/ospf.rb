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
      network             => {
        192.168.0.0 => {
          area => 0.0.0.0,
        },
      },
      redistribute        => {
        ..
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
        raise ArgumentError, '\'%s\' has an unsupported type' % value
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


  newproperty(:network) do
    desc %q{ Enable routing on an IP network. }

    validate do |value|
      case value
      when String
        if value.include?('=>') or value =~ /\w:\s*([\w\{])/
          begin
            hash = eval(value.gsub(/(\w):\s*([\w\{])/, '\1 => \2').gsub(/:?([\w\.\/]+)/, '\'\1\''))
          rescue SyntaxError => e
            raise ArgumentError, '\'%s\' is not a Hash' % value
          end
          hash.each do |network, area|
            unless network =~ /\A\d+\.\d+\.\d+\.\d+\/\d+\Z/
              raise ArgumentError, '\'%s\' is not a valid network' % network
            end
            if area.has_key?('area')
              unless area['area'] =~ /\A\d+\.\d+\.\d+\.\d+\Z/
                raise ArgumentError, '\'%s\' is not a valid area' % area['area']
              end
            else
              raise ArgumentError, '\'%s\' should contain a \'area\' key' % network
            end
          end
        else
          raise ArgumentError, 'The property should be a Hash'
        end
      when Hash
        value.each do |network, area|
          unless network =~ /\A\d+\.\d+\.\d+\.\d+\/\d+\Z/
            raise ArgumentError, '\'%s\' is not a valid network' % network
          end
          if area.has_key?('area')
            unless area['area'] =~ /\A\d+\.\d+\.\d+\.\d+\Z/
              raise ArgumentError, '\'%s\' is not a valid area' % area['area']
            end
          elsif area.has_key?(:area)
            unless area[:area] =~ /\A\d+\.\d+\.\d+\.\d+\Z/
              raise ArgumentError, '\'%s\' is not a valid area' % area[:area]
            end
          else
            raise ArgumentError, '\'%s\' should contain a \'area\' key' % network
          end
        end
      else
        raise ArgumentError, 'The property should be a Hash'
      end
    end

    munge do |value|
      case value
      when String
        hash = eval(value.gsub(/(\w):\s*([\w\{])/, '\1 => \2').gsub(/:?([\w\.\/]+)/, '\'\1\''))
        new_hash = {}
        hash.each do |network, area|
          new_hash[network] = { :area => area['area'] }
        end
        new_hash
      when Hash
        new_hash = {}
        value.each do |network, area|
          if area.has_key?('area')
            new_hash[network] = { :area => area['area']}
          else
            new_hash[network] = area
          end
        end
        new_hash
      else
        value
      end
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
