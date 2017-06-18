Puppet::Type.type(:quagga_prefix_list).provide :quagga do
  @doc = %q{ Manages prefix lists using quagga }

  @known_resources = [
      :action, :prefix, :ge, :le, :proto,
  ]

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    debug '[instances]'
    providers = []
    found_prefix_list = false

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      next if line =~ /\A!\Z/

      if line =~ /^(ip|ipv6) prefix-list ([\w-]+) seq (\d+) (permit|deny) ([\d\.\/:]+|any)( (ge|le) (\d+)( (ge|le) (\d+))?)?$/

        hash = {
            :action => $4.to_sym,
            :ensure => :present,
            :name => "#{$2}:#{$3}",
            :prefix => $5,
            :proto => $1.to_sym,
            :provider => self.name,
        }

        hash[$7.to_sym] = $8.to_i unless $7.nil?
        hash[$10.to_sym] = $11.to_i unless $10.nil?

        debug "prefix_list: #{hash}"

        providers << new(hash)

        found_prefix_list = true unless found_prefix_list

      elsif line =~ /\A\w/ and found_prefix_list
        break
      end
    end

    providers
  end

  def self.prefetch(resources)
    debug '[prefetch]'
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find{ |prefix_list| prefix_list.name == name }
        resources[name].provider = provider
        provider.purge
      end
    end
  end

  def create
    debug '[create]'
    known_resources = self.class.instance_variable_get('@known_resources')

    @property_hash[:ensure] = :present
    @property_hash[:name] = @resource[:name]

    known_resources.each do |property|
      self.method("#{property}=").call(@resource[property]) unless @resource[property].nil?
    end
  end

  def destroy
    debug '[destroy]'
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    name, sequence = (@property_hash[:name].nil? ? @resource[:name] : @property_hash[:name]).split(/:/)

    debug "[flush][#{name}:#{sequence}]"

    cmds = []
    cmds << 'configure terminal'
    if @property_hash[:ensure] == :absent
      proto = @property_hash[:proto]
      action = @property_hash[:action]
      prefix = @property_hash[:prefix]
      ge = @property_hash[:ge]
      le = @property_hash[:le]

      cmd = ''
      cmd << "no #{proto} prefix-list #{name} seq #{sequence} #{action} #{prefix}"
      cmd << " ge #{ge}" unless ge.nil?
      cmd << " le #{le}" unless le.nil?

      cmds << cmd
    else
      proto = @resource[:proto]
      action = @resource[:action]
      prefix = @resource[:prefix]
      ge = @resource[:ge]
      le = @resource[:le]

      cmd = ''
      cmd << "#{proto} prefix-list #{name} seq #{sequence} #{action} #{prefix}"
      cmd << " ge #{ge}" unless ge.nil?
      cmd << " le #{le}" unless le.nil?

      cmds << cmd
    end
    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })
  end

  def purge
    debug '[purge]'

    known_resources = self.class.instance_variable_get('@known_resources')
    known_resources.each do |property|
      if @resource[property].nil? && !@property_hash[property].nil?
        flush
        break
      end
    end
  end
end
