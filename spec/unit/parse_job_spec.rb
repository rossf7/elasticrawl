require 'spec_helper'

describe Elasticrawl::ParseJob do
  describe '#set_segments' do
    let(:job_name) { (Time.now.to_f * 1000).to_i.to_s }
    let(:job_desc) { 'Crawl: CC-MAIN-2013-20 Segments: 2 Parsing: 5 files per segment' }
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2013-20') }
    let(:max_files) { 5 }
    let(:parse_job) { Elasticrawl::ParseJob.new }

    before do
      crawl.create_segments
      parse_job.set_segments(crawl.crawl_segments[0..1], max_files)
    end

    it 'should have a job name based on current time' do
      expect(parse_job.job_name.slice(0, 8)).to eq job_name.slice(0, 8)
    end

    it 'should have a job desc' do
      expect(parse_job.job_desc).to eq job_desc
    end

    it 'should create 2 job steps' do
      expect(parse_job.job_steps.count).to eq 2
    end

    it 'should set steps input path to segment uri' do
      input_path = parse_job.job_steps[0].input_paths
      segment_uri = crawl.crawl_segments[0].segment_s3_uri

      expect(input_path.starts_with?(segment_uri)).to eq true
    end

    it 'should set output path' do
      output_path = parse_job.job_steps[0].output_path
      segment_name = crawl.crawl_segments[0].segment_name

      expect(output_path.include?(parse_job.job_name)).to eq true
      expect(output_path.include?(segment_name)).to eq true
    end
  end

  describe '#confirm_message' do
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2013-20') }
    let(:job) { Elasticrawl::ParseJob.new }
    let(:job_desc) { 'Crawl: CC-MAIN-2013-20 Segments: 3 Parsing: 5 files per segment' }
    let(:cluster_desc) {
      cluster_desc = <<-HERE
Cluster configuration
Master: 1 m1.medium  (Spot: 0.12)
Core:   2 m1.medium  (Spot: 0.12)
Task:   --
      HERE
    }

    before do
      crawl.create_segments
      job.set_segments(crawl.crawl_segments[0..2], 5)
    end

    it 'should display message including job desc' do
      expect(job.confirm_message.include?(job_desc)).to eq true
    end

    it 'should display message including cluster desc' do
      expect(job.confirm_message.include?(cluster_desc)).to eq true
    end
  end

  describe '#run' do
    let(:crawl_name) { 'CC-MAIN-2013-20' }
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => crawl_name) }
    let(:job) { Elasticrawl::ParseJob.new }
    let(:job_flow_id) { 'j-3QHDKKBT6VAIS' }

    before do
      crawl.create_segments
      job.set_segments(crawl.crawl_segments[0..1], 5)

      allow_any_instance_of(Elasticity::JobFlow).to receive(:run).and_return(job_flow_id)
      job.run
    end

    it 'should set a job flow id' do
      expect(job.job_flow_id).to eq job_flow_id
    end

    it 'should set parse time for parsed segments' do
      expect(crawl.crawl_segments[0].parse_time.present?).to eq true
      expect(crawl.crawl_segments[1].parse_time.present?).to eq true
      expect(crawl.crawl_segments[2].parse_time.present?).to eq false
    end
  end

  describe '#log_uri' do
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2013-20') }
    let(:job) { Elasticrawl::ParseJob.new }

    before do
      crawl.create_segments
      job.set_segments(crawl.crawl_segments)
    end

    it 'should set a log uri including the job name' do
      expect(job.log_uri).to eq "s3://elasticrawl/logs/1-parse/#{job.job_name}/"
    end
  end

  describe '#history' do
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2013-20') }
    let(:job) { Elasticrawl::ParseJob.new }
    let(:job_desc) { 'Crawl: CC-MAIN-2013-20 Segments: 3 Parsing: all files' }
    let(:job_flow_id) { 'j-3QHDKKBT6VAIS' }

    before do
      crawl.create_segments
      job.set_segments(crawl.crawl_segments)

      allow_any_instance_of(Elasticity::JobFlow).to receive(:run).and_return(job_flow_id)
      job.run
    end

    it 'should return the job name, history and launch time' do
      expect(job.history.include?(job.job_name)).to eq true
      expect(job.history.include?(job.job_desc)).to eq true
      expect(job.history.include?(job.created_at.strftime('%Y-%m-%d %H:%M:%S'))).to eq true
    end
  end
end
