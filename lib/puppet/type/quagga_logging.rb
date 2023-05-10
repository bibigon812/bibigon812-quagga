Puppet::Type.newtype(:quagga_logging) do
  @doc = "This type provides the capabilities to manage logging within puppet.

    Examples:

      quagga_logging { 'file':
        file_name => '/tmp/quagga.errors.log',
        level     => 'debugging,
      }

      quagga_logging { 'syslog':
        facility => 'local7',
        level    => 'warnings',
      }
  "

  ensurable

  newparam(:name) do
    desc 'Specifies a backend name of the logging system. The values are:
        - file /path/to/file
        - monitor
        - stdout
        - syslog
    '

    newvalues('file', 'monitor', 'stdout', 'syslog')
  end

  # newproperty(:facility) do
  #   desc %q{Specifies facility parameter for syslog messages. The values are:
  #       - auth
  #       - cron
  #       - daemon
  #       - kern
  #       - local0
  #       - local1
  #       - local2
  #       - local3
  #       - local4
  #       - local5
  #       - local6
  #       - local7
  #       - lpr
  #       - mail
  #       - news
  #       - syslog
  #       - user
  #       - uucp
  #   }

  #   defaultto(:daemon)
  #   newvalues(:auth, :cron, :daemon, :kern, :local0, :local1, :local2, :local3, :local4,
  #     :local5, :local6, :local7, :lpr, :mail, :news, :syslog, :user, :uucp)
  # end

  newproperty(:filename) do
    desc 'Specifies the filename for file messages.'
  end

  newproperty(:level) do
    desc 'Specifies the logging level. The values are:
        - alerts
        - critical
        - debugging
        - emergencies
        - errors
        - informational
        - notifications
        - warnings
    '

    newvalues(:alerts, :critical, :debugging, :emergencies, :errors, :informational, :notifications, :warnings)
  end

  autorequire(:package) do
    ['quagga', 'frr']
  end

  autorequire(:service) do
    ['zebra', 'frr']
  end
end
