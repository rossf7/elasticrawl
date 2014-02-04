require 'spec_helper'

describe Elasticrawl::CombineJob do
  describe '#set_input_jobs' do
    let(:job_name) { (Time.now.to_f * 1000).to_i.to_s }
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2013-20') }
    let(:segment_list_1) { crawl.crawl_segments[0..1] }
    let(:segment_list_2) { [crawl.crawl_segments[2]]}

    let(:parse_job_1) { Elasticrawl::ParseJob.new }
    let(:parse_job_2) { Elasticrawl::ParseJob.new }
    let(:combine_job) { Elasticrawl::CombineJob.new }

    before do
      crawl.create_segments
      parse_job_1.set_segments(segment_list_1)
      parse_job_2.set_segments(segment_list_2)

      input_jobs = [parse_job_1.job_name, parse_job_2.job_name]
      combine_job.set_input_jobs(input_jobs)
    end

    it 'should have a job name based on current time' do
      expect(combine_job.job_name.slice(0, 8)).to eq job_name.slice(0, 8)
    end

    it 'should have a job desc' do
      expect(combine_job.job_desc.end_with?('Combining: 3 segments')).to eq true
    end

    it 'should create 1 job step' do
      expect(combine_job.job_steps.count).to eq 1
    end

    it 'should set 1 input path per parse job' do
      input_paths = combine_job.job_steps[0].input_paths
      expect(input_paths.split(',').count).to eq 2
    end

    it 'should set input path including parse job name' do
      input_paths = combine_job.job_steps[0].input_paths
      expect(input_paths.include?(parse_job_1.job_name)).to eq true
    end

    it 'should set input path without segment names' do
      input_paths = combine_job.job_steps[0].input_paths
      segment_name = segment_list_1[0].segment_name
      expect(input_paths.include?(segment_name)).to eq false
    end

    it 'should set output path including job name' do
      output_path = combine_job.job_steps[0].output_path
      expect(output_path.include?(combine_job.job_name)).to eq true
    end
  end

  describe '#run' do
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2013-20') }
    let(:parse_job_1) { Elasticrawl::ParseJob.new }
    let(:parse_job_2) { Elasticrawl::ParseJob.new }
    let(:combine_job) { Elasticrawl::CombineJob.new }
    let(:job_flow_id) { 'j-3QHDKKBT6VAIS' }

    before do
      crawl.create_segments
      parse_job_1.set_segments(crawl.crawl_segments[0..1])
      parse_job_2.set_segments([crawl.crawl_segments[2]])

      input_jobs = [parse_job_1.job_name, parse_job_2.job_name]
      combine_job.set_input_jobs(input_jobs)
    end

    it 'should set a job flow id' do
      Elasticity::JobFlow.any_instance.stubs(:run).returns(job_flow_id)
      combine_job.run

      expect(combine_job.job_flow_id).to eq job_flow_id
    end
  end

  describe '#log_uri' do
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2013-20') }
    let(:parse_job) { Elasticrawl::ParseJob.new }
    let(:job) { Elasticrawl::CombineJob.new }

    before do
      crawl.create_segments
      parse_job.set_segments(crawl.crawl_segments)

      job.set_input_jobs([parse_job.job_name])
    end

    it 'should set a log uri including the job name' do
      expect(job.log_uri).to eq "s3://elasticrawl/logs/2-combine/#{job.job_name}/"
    end
  end
end
