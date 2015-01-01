require 'spec_helper'

describe Elasticrawl::Crawl do
  it { should have_many(:crawl_segments) }
  it { should have_db_column(:crawl_name).of_type(:string) }

  describe '#has_segments?' do
    let(:crawl_name) { 'CC-MAIN-2014-49' }
    subject { Elasticrawl::Crawl.new(:crawl_name => crawl_name) }

    it 'should have segments' do
      expect(subject.has_segments?).to eq true
    end
  end

  describe '#create_segments' do
    let(:crawl_name) { 'CC-MAIN-2014-49' }
    subject { Elasticrawl::Crawl.create(:crawl_name => crawl_name) }

    before do
      subject.create_segments
    end

    it 'should set crawl name' do
      expect(subject.crawl_name).to eq crawl_name
    end

    it 'should create correct # of segments' do
      expect(subject.crawl_segments.count).to eq 3
    end

    it 'should create segment names' do
      expect(subject.crawl_segments[0].segment_name).to eq '1416400372202.67'
    end

    it 'should create segment s3 uris' do
      expect(subject.crawl_segments[0].segment_s3_uri).to eq \
        's3://aws-publicdatasets/common-crawl/crawl-data/CC-MAIN-2014-49/segments/1416400372202.67/'
    end

    it 'should set file counts' do
      expect(subject.crawl_segments[0].file_count).to eq 3
    end
  end

  describe '#next_segments' do
    let(:crawl_name) { 'CC-MAIN-2014-49' }
    subject { Elasticrawl::Crawl.create(:crawl_name => crawl_name) }

    before do
      subject.create_segments
    end

    it 'should return all segments' do
      crawl_segments = subject.next_segments

      expect(crawl_segments.count).to eq 3
      expect(crawl_segments[0].crawl.crawl_name).to eq crawl_name
      expect(crawl_segments[0].segment_name).to eq '1416400372202.67'
    end

    it 'should return first # segments' do
      crawl_segments = subject.next_segments(2)

      expect(crawl_segments.count).to eq 2
      expect(crawl_segments[0].crawl.crawl_name).to eq crawl_name
      expect(crawl_segments[0].segment_name).to eq '1416400372202.67'
    end
  end

  describe '#select_segments' do
    let(:crawl_name) { 'CC-MAIN-2014-49' }
    subject { Elasticrawl::Crawl.create(:crawl_name => crawl_name) }

    before do
      subject.create_segments
    end

    it 'should select no segments' do
      segments_list = ['test', 'segment']
      crawl_segments = subject.select_segments(segments_list)

      expect(crawl_segments.count).to eq 0
    end

    it 'should select only segments in list' do
      segments_list = ['1416400372202.67', '1416400372490.23']
      crawl_segments = subject.select_segments(segments_list)

      expect(crawl_segments.count).to eq 2
    end
  end

  describe '#reset' do
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2014-49') }
    let(:job) { Elasticrawl::ParseJob.new }
    let(:job_flow_id) { 'j-3QHDKKBT6VAIS' }

    before do
      crawl.create_segments
      job.set_segments(crawl.crawl_segments[0..1])

      allow_any_instance_of(Elasticity::JobFlow).to receive(:run).and_return(job_flow_id)
      job.run

      crawl.reset
    end

    it 'should set parse time of all segments to null' do
      unparsed_segments = Elasticrawl::CrawlSegment.where(:parse_time => nil).count
      expect(crawl.crawl_segments.count).to eq unparsed_segments
    end
  end

  describe '.status' do
    let(:job_desc) { 'Crawl: CC-MAIN-2014-49 Segments: 2 Parsing: 3 files per segment' }
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2014-49') }
    let(:max_files) { 3 }
    let(:job) { Elasticrawl::ParseJob.new }
    let(:job_flow_id) { 'j-3QHDKKBT6VAIS' }

    before do
      crawl.create_segments
      job.set_segments(crawl.crawl_segments[0..1], max_files)

      allow_any_instance_of(Elasticity::JobFlow).to receive(:run).and_return(job_flow_id)
      job.run
    end

    it 'should display status of crawl segments' do
      expect(Elasticrawl::Crawl.status.split("\n")[1]).to eq \
        'CC-MAIN-2014-49 Segments: to parse 1, parsed 2, total 3'
    end

    it 'should display parse job desc' do
      crawl_status = Elasticrawl::Crawl.status.split("\n")[4]

      expect(crawl_status.include?(job.job_name)).to eq true
      expect(crawl_status.include?(job.job_desc)).to eq true
    end
  end
end
