Puppet::Type.type(:quagga_logging).provide :quagga do
  @doc = 'Manages quagga logging parameters.'

  mk_resource_methods

  commands vtysh: 'vtysh'

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    providers = []
    hash = {}
    find = false

    vtysh('-c', 'show running-config').split(%r{\n}).map do |line|
      find = true if !find && (%r{\Alog\s} =~ line)
      find = false if find && !(%r{\Alog\s} =~ line)
      next unless find

      %r{\Alog\s(?<name>(?:file\s(?<filename>\S+)|monitor|stdout|syslog))(?:\s(?<level>\S+))?\Z}.match(line) do |m|
        hash = {
          ensure:   :present,
          provider: name,
        }

        if m[:filename].nil?
          hash[:name] = m[:name].to_sym
        else
          hash[:name]     = :file
          hash[:filename] = m[:filename]
        end

        hash[:level] = if m[:level].nil?
                         if hash[:name] == 'monitor'
                           :debugging
                         else
                           :errors
                         end
                       else
                         m[:level].to_sym
                       end

        debug "Instantiated quagga_logging: #{hash.inspect}"
        providers << new(hash)
      end
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.each_key do |name|
      if (provider = providers.find { |prov| prov.name == name })
        resources[name].provider = provider
      end
    end
  end

  def create
    Puppet.debug "Creating the logging method #{@resource[:name]}"

    @property_hash[:name] = @resource[:name]
    @property_hash[:ensure] = :present
    @property_hash[:level] = @resource[:level]
    @property_hash[:filename] = @resource[:filename]

    @property_flush = @property_hash
  end

  def destroy
    name = @property_hash[:name]
    Puppet.debug "Destroying the logging method #{name}"
    @property_hash[:ensure] = :absent
    @property_flush = @property_hash
  end

  def flush
    return if @property_flush.empty?
    Puppet.debug "Flushing #{@property_hash[:name]}"
    commands = []
    commands << 'configure terminal'

    if exists?
      command = ['log']
      command << @property_hash[:name]

      if @property_hash[:name] == 'file'
        command << filename
      end

      command << level unless level == :absent

      commands << command.join(' ')

    else

      commands << "no log #{@property_hash[:name]}"
    end

    commands << 'end'
    commands << 'write memory'

    vtysh(commands.reduce([]) { |cmdsx, cmd| cmdsx << '-c' << cmd })

    @property_hash = @resource.to_hash
    @property_flush.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  [:filename, :level].each do |property|
    define_method property.to_s do
      @property_hash[property] || :absent
    end

    define_method "#{property}=" do |value|
      @property_flush[property] = @property_hash[property] = value
    end
  end
end
