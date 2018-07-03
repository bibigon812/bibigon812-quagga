# @summary Logging
#
class quagga::logging (
  Variant[
    Enum['monitor', 'stdout', 'syslog'],
    Pattern[/\Afile\s(\/\S+)+\Z/]
  ]                              $backend,
  Optional[Stdlib::Absolutepath] $filename,
  Enum[
    'alerts',
    'critical',
    'debugging',
    'emergencies',
    'errors',
    'informational',
    'notifications',
    'warnings'
  ]                              $level,
) {
  quagga_logging { $backend:
    filename => $filename,
    level    => $level,
  }
}
