Puppet::Type.type(:ospf_area).provide :quagga do
  @doc = %q{ Manages OSPF areas using quagga }

  @resource_map = {
    :default_cost       => { :type => :Fixnum, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sdefault-cost\s(\d+)\Z/ },
    :access_list_export => { :type => :String, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sexport-list\s([\w-]+)\Z/ },
    :access_list_import => { :type => :String, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\simport-list\s([\w-]+)\Z/ },
    :prefix_list_export => { :type => :String, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sfilter-list\sprefix\s([\w-]+)\sout\Z/ },
    :prefix_list_import => { :type => :String, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sfilter-list\sprefix\s([\w-]+)\sin\Z/ },
    :shortcut           => { :type => :Symbol, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sshortcut\s(default|enable|disable)\Z/, :default => :default },
    :stub               => { :type => :Symbol, :regexp => /\A\sarea\s(\d+\.\d+\.\d+\.\d+)\sstub(\sno-summary)?\Z/, :default => :false },
    :network            => { :type => :Array,  :regexp => /\A\snetwork\s(\d+\.\d+\.\d+\.\d+\/\d+)\sarea\s(\d+\.\d+\.\d+\.\d+)\Z/}
  }

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    ospf_areas = []
    debug '[instances]'
    hash = {}
    found_router = false
    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      next if line =~ /\A!\Z/
      if line =~ /\Arouter ospf\Z/
        found_router = true
      elsif line =~ /\A\w/ && found_router
        found_router = false
      # TODO:
      elsif found_router
        @resource_map.each do |property, options|
          if line =~ options[:regexp]
            first_param = $1
            second_param = $2

            if property == :network
              area = second_param
              value = first_param
            else
              area = first_param
              value = second_param
            end

            value = true if value.nil?

            case options[:type]
            when :Array
              munged_value = [ value ]
            when :Fixnum
              munged_value = value.to_i
            when :Symbol
              munged_value = value.to_s.gsub(/-/, '_').to_sym
            else
              munged_value = value
            end

            if provider = ospf_areas.find { |provider| provider.name == area }
              if options[:type] == :Array
                prev_value = provider.method("#{property}").call
                prev_value = prev_value == :absent ? [] : prev_value
                provider.method("#{property}=").call((prev_value << value).sort)
              else
                provider.method("#{property}=").call(munged_value)
              end
            else
              hash = {
                :ensure => :present,
                :name => area,
                :provider => self.name
              }
              @resource_map.each do |property, options|
                if options.has_key?(:default)
                  hash[property] = options[:default]
                end
              end
              hash[property] = munged_value
              ospf_areas << new(hash)
            end
          end
        end
      end
    end
    ospf_areas
  end

  def self.prefetch(resources)
    providers = instances
    found_providers = []
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
        found_providers << provider
      end
    end
  end
end
