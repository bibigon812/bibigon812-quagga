# @summary Logging
#
# @param backend
#   The quagga logging backend.
#
# @param filename
#   If the backend is set to file, use this file as the output
#
# @param level
#   The log level
class quagga::logging (
  Variant[
    Enum['monitor', 'stdout', 'syslog'],
    Pattern[/\Afile\s(\/\S+)+\Z/]
  ]                              $backend,
  Optional[Stdlib::Absolutepath] $filename,
  Enum['alerts','critical','debugging','emergencies','errors','informational','notifications','warnings']
  $level,
) {
  quagga_logging { $backend:
    filename => $filename,
    level    => $level,
  }
}
