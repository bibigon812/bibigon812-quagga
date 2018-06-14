Puppet::Type.type(:quagga_logging).provide :quagga do
  @doc = %q{Manages quagga logging parameters.}

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
    store = {}

    vtysh('-c', 'show running-config').split(%r{\n}).collect do |line|
      find = true if not find and %r{\Alog\s} =~ line
      find = false if find and not %r{\Alog\s} =~ line
      next unless find

      %r{\Alog\s(?<name>(?:file\s(?<filename>\S+)|monitor|stdout|syslog))(?:\s(?<level>\S+))?\Z}.match(line) do |m|

        hash = {
          ensure:   :present,
          provider: self.name,
        }

        if m[:filename].nil?
          hash[:name] = m[:name]
        else
          hash[:name]     = 'file'
          hash[:filename] = m[:filename]
        end

        if m[:level].nil?
          if name == 'monitor'
            hash[:level] = :debugging
          else
            hash[:level] = :errors
          end
        else
          hash[:level] = m[:level].to_sym
        end

        debug 'Instantiated quagga_logging: %{hash}' % { hash: store.inspect }
        providers << new(hash)
      end
    end

    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find{ |provider| provider.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    @property_hash[:ensure] = :present
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def flush
    cmds = []
    cmds << 'configure terminal'

    if exists?

      cmd = %w{log}
      cmd << @property_hash[:name]

      if @property_hash[:name] == 'file'
        cmd << filename
      end

      cmd << level unless level == :absent

      cmds << cmd.join(' ')

    else

      cmds << 'no log %{name}' % { name: name }
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]) { |cmds, cmd| cmds << '-c' << cmd })

    @property_flush.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  [:filename, :level].each do |property|
    define_method "#{property}" do
      @property_hash[property] || :absent
    end

    define_method "#{property}=" do |value|
      @property_flush[property] = @property_hash[property] = value
    end
  end
end
