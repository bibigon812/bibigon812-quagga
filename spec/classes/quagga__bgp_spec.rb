require 'spec_helper'

describe 'quagga::bgp' do
  it { is_expected.to compile.with_all_deps }
end
