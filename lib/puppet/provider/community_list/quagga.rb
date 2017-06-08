Puppet::Type.type(:community_list).provide :quagga do
  @doc = %q{ Manages a community-list using quagga }

  commands :vtysh => 'vtysh'

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    debug '[instances]'

    providers = []
    hash = {}
    previous_name = ''
    found_community_list = false

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      next if line =~ /\A!\Z/

      if line =~ /\Aip\scommunity-list\s(\d+)\s(deny|permit)((\s(\d+:\d+))+)\Z/
        name = $1
        action = $2
        communities = $3.strip.split(/\s/)
        found_community_list = true

        if name != previous_name
          unless hash.empty?
            debug "community_list: #{hash}"
            providers << new(hash)
          end
          hash = {}
          hash[:ensure] = :present
          hash[:provider] = self.name
          hash[:name] = name
          hash[:rules] = []
        end

        communities.each do |community|
          hash[:rules] << {action.to_sym => community}
        end

        previous_name = name
      elsif line =~ /^\w/ and found_community_list
        break
      end
    end

    unless hash.empty?
      debug "community_list: #{hash}"
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
    @property_hash[:name] = @resource[:name]
    @property_hash[:ensure] = :present
    self.rules = @resource[:rules]
  end

  def destroy
    debug '[destroy]'
    @property_hash[:ensure] = :absent
    self.rules = []
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def rules
    @property_hash[:rules] || :absent
  end

  def rules=(value)
    debug '[rules=]'
    name = @property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]

    cmds = []
    cmds << 'configure terminal'


    cmds << "no ip community-list #{name}"

    value.each do |rule|
      rule.each do |action, community|
        cmds << "ip community-list #{name} #{action} #{community}"
      end
    end

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash[:rules] = value
  end
end