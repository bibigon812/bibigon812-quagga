require 'spec_helper_acceptance'

describe 'quagga' do
  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'quagga': }
        quagga_ospf { 'ospf':
          ensure => present,
          router_id => '1.1.1.1',
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end
  end
end
