Puppet::Type.type(:quagga_as_path).provide :quagga do
  @doc = %q{
    Manages as-path access-list using quagga.
  }

  commands :vtysh => 'vtysh'

  def self.instances
    debug '[instances]'

    providers = []
    hash = {}
    previous_name = ''

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|
      if line =~ /\Aip\sas-path\saccess-list\s([\w]+)\s(permit|deny)\s(.+)\Z/
        name = $1
        action = $2
        regex = $3

        unless name == previous_name
          unless hash.empty?
            debug "as-path list: #{hash}"
            providers << new(hash)
          end

          hash = {
              :ensure => :present,
              :name => name,
              :provider => self.name,
              :rules => [],
          }
        end

        hash[:rules] << { action.to_sym => regex }

        previous_name = name
      end
    end

    unless hash.empty?
      debug "as-path list: #{hash}"
      providers << new(hash)
    end
    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    debug '[create]'
    @property_hash[:ensure] = :present
    @property_hash[:name] = @resource[:name]

    self.rules = @resource[:rules]
  end

  def destroy
    debug '[destroy]'

    @property_hash[:ensure] = :absent

    self.rules = []

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def rules
    @property_hash[:rules] || :absent
  end

  def rules=(value)
    debug '[rules=]'
    name = @property_hash[:name]

    cmds = []
    cmds << 'configure terminal'

    cmds << "no ip as-path access-list #{name}"

    value.each do |rule|
      rule.each do |action, regex|
        cmds << "ip as-path access-list #{name} #{action} #{regex}"
      end
    end

    cmds << 'end'
    cmds << 'write memory'

    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash[:rules] = value
  end
end