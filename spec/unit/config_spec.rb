require 'spec_helper'

describe Elasticrawl::Config do
  describe '#load_config' do
    subject { Elasticrawl::Config.new }

    it 'should return a hash of config data' do
      config_data = subject.load_config('jobs')
      expect(config_data).to be_a Hash
    end

    it 'should load yaml config file' do
      config_data = subject.load_config('jobs')
      expect(config_data['s3_bucket_name']).to eq 'elasticrawl'
    end
  end
end
