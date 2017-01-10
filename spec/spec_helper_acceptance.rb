require 'beaker-rspec'

install_puppet_agent_on(hosts, options)
# hosts.each do |host|
#   # Install Puppet
#   on host, install_puppet
# end

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  module_name = module_root.split('-').last

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    hosts.each do |host|
      install_dev_puppet_module_on(host, :source => module_root,
          :module_name => module_name)
      # Install dependencies
      on(host, puppet('module', 'install', 'puppetlabs-stdlib'))
    end
  end
end
