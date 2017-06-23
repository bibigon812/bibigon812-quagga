require 'spec_helper'

describe 'quagga::system' do
  it { is_expected.to compile.with_all_deps }
end
