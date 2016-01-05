require 'spec_helper'

describe Elasticrawl::JobStep, type: :model do
  it { should belong_to(:job) }
  it { should belong_to(:crawl_segment) }
  it { should have_db_column(:input_paths).of_type(:text) }
  it { should have_db_column(:output_path).of_type(:text) }

  describe '#job_flow_step' do
    let(:job) { Elasticrawl::ParseJob.create(:job_name => '1389789645620',
                                              :max_files => 3) }
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2014-49') }
    let(:crawl_segment) { crawl.crawl_segments[0] }
    let(:input_paths) {
      's3://aws-publicdatasets/common-crawl/crawl-data/CC-MAIN-2014-49/segments/1368696381249/wet/*.warc.wet.gz'
    }
    let(:output_path) {
      's3://elasticrawl/data/1-parse/1389789645620/segments/1368696381249/'
    }
    let(:config) {
      { 'jar' => 's3://elasticrawl/jar/elasticrawl-example-0.0.1.jar',
        'class' => 'com.rossfairbanks.commoncrawl.elasticrawl.ParserDriver'
      }
    }

    let(:job_step) { Elasticrawl::JobStep.create(:job => job,
                                          :crawl_segment => crawl_segment,
                                          :input_paths => input_paths,
                                          :output_path => output_path) }
    subject { job_step.job_flow_step(config) } 

    it 'should be a CustomJarStep' do
      expect(subject).to be_a Elasticity::CustomJarStep
    end

    it 'should have a jar location' do
      expect(subject.jar).to eq config['jar']
    end

    it 'should have 4 jar args' do
      expect(subject.arguments.count).to eq 4
    end

    it 'should have a class argument' do
      expect(subject.arguments[0]).to eq config['class']
    end

    it 'should have an input path arg' do
      expect(subject.arguments[1]).to eq input_paths
    end

    it 'should have an output path arg' do
      expect(subject.arguments[2]).to eq output_path
    end

    it 'should have a max files arg' do
      expect(subject.arguments[3]).to eq '3'
    end
  end
end
