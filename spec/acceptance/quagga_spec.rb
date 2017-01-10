require 'spec_helper_acceptance'

describe 'quagga' do
  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'quagga': }
        ospf_interface { 'lo':
          ensure              => present,
          cost                => 100,
          dead_interval       => 8,
          hello_interval      => 2,
          network_type        => broadcast,
          retransmit_interval => 4,
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end
  end
end
