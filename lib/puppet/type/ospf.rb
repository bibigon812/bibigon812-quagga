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

    originate_attributes = [:always, :metric, :metric_type, :route_map]

    defaultto(:false)

    validate do |value|
      case value
      when String
        if value.include?('=>')
          begin
            hash = eval(value.gsub(/([\w-]+)/, '\'\1\''))
          rescue SyntaxError => e
            raise ArgumentError, '\'%s\' is not a Hash' % value
          end
          if hash.has_key?('originate')
            hash['originate'].each_key do |key|
              unless originate_attributes.include?(key.gsub(/-/, '_').to_sym)
                raise ArgumentError, '\'%s\' is not a valid originate attribute' % key
              end
            end
          else
            raise ArgumentError, '\'%s\' must be \'originate\'' % hash.keys.first
          end
        else
          array = value.split(/\s+/)
          unless array.shift == 'originate'
            raise ArgumentError, 'first word must be \'originate\''
          end
          while not array.empty?
            attribute = array.shift.gsub(/-/, '_').to_sym
            unless originate_attributes.include?(attribute)
              raise ArgumentError, '\'%s\' is not a valid originate attribute' % attribute
            end
            unless attribute == :always
              array.shift
            end
          end
        end
      when Symbol
        unless value == :false or value == :originate
          raise ArgumentError, '\'%s\' is an unknown value' % value
        end
      when FalseClass
      when Hash
        if value.has_key?(:originate)
          value[:originate].each_key do |key|
            unless originate_attributes.include?(key.to_s.gsub(/-/, '_').to_sym)
              raise ArgumentError, '\'%s\' is not a valid originate attribute' % key
            end
          end
        elsif value.has_key?('originate')
          value['originate'].each_key do |key|
            unless originate_attributes.include?(key.to_s.gsub(/-/, '_').to_sym)
              raise ArgumentError, '\'%s\' is not a valid originate attribute' % key
            end
          end
        else
          raise ArgumentError, '\'originate\' attribute not found'
        end
      else
        raise ArgumentError, '\'%s\' is an unknown value' % value
      end
    end

    munge do |value|
      if value.is_a?(String)
        if value.include?('=>')
          hash = eval(value.gsub(/([\w-]+)/, '\'\1\''))
          new_hash = {}
          new_hash[:originate] = {}
          hash['originate'].each do |key, value|
            attribute = key.gsub(/-/, '_').to_sym
            if originate_attributes.include?(attribute)
              case attribute
              when :always
                new_hash[:originate][attribute] = :true
              when :metric, :metric_type
                new_hash[:originate][attribute] = value.to_i
              else
                new_hash[:originate][attribute] = value
              end
            end
          end
          new_hash
        else
          array = value.split(/\s/)
          new_hash = {}
          new_hash[:originate] = {}
          array.shift
          while not array.empty?
            attribute = array.shift.gsub(/-/, '_').to_sym
            if originate_attributes.include?(attribute)
              case attribute
              when :always
                new_hash[:originate][:always] = :true
              when :metric_type, :metric
                new_hash[:originate][attribute] = array.shift.to_i
              else
                new_hash[:originate][attribute] = array.shift
              end
            end
          end
          new_hash
        end
      else
        value
      end
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
