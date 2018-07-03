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
    store = {}

    vtysh('-c', 'show running-config').split(%r{\n}).collect do |line|
      find = true if !find && (/\Alog\s/ =~ line)
      find = false if find && !(/\Alog\s/ =~ line)
      next unless find

      /\Alog\s(?<name>(?:file\s(?<filename>\S+)|monitor|stdout|syslog))(?:\s(?<level>\S+))?\Z/.match(line) do |m|
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
          if hash[:name] == 'monitor'
            hash[:level] = :debugging
          else
            hash[:level] = :errors
          end
        else
          hash[:level] = m[:level].to_sym
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
      if provider = providers.find{ |prov| prov.name == name }
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
    commands = []
    commands << 'configure terminal'

    if exists?

      command = %w[log]
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

    vtysh(commands.reduce([]) { |cmds, cmd| cmds << '-c' << cmd })

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
