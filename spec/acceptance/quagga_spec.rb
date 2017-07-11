require 'spec_helper_acceptance'

describe 'quagga' do
  let(:hiera_config) { 'spec/data/hiera.yaml' }
  let(:manifest) {
    'include quagga'
  }

  it 'should apply without errors' do
    apply_manifest(manifest, :catch_failures => true)
  end

  it 'should apply a second time without changes' do
    @result = apply_manifest(manifest)
    expect(@result.exit_code).to be_zero
  end
end
