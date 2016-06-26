require 'spec_helper'

describe Elasticrawl::CrawlSegment, type: :model do
  it { should belong_to(:crawl) }
  it { should have_many(:job_steps) }
  it { should have_db_column(:segment_name).of_type(:string) }
  it { should have_db_column(:segment_s3_uri).of_type(:string) }
  it { should have_db_column(:parse_time).of_type(:datetime) }
  it { should have_db_column(:file_count).of_type(:integer) }

  describe '.create_segment' do
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2014-49') }
    let(:segment_name) { '1416400372202.67' }
    let(:file_count) { 3 }
    let(:segment_desc) { 'Segment: 1416400372202.67 Files: 3' }
    subject { Elasticrawl::CrawlSegment.create_segment(crawl,
                                                       segment_name,
                                                       file_count) }
    it 'should have a segment name' do
      expect(subject.segment_name).to eq segment_name
    end

    it 'should have an s3 uri' do
      expect(subject.segment_s3_uri).to eq \
        "s3://commoncrawl/crawl-data/#{crawl.crawl_name}/segments/#{segment_name}/"
    end

    it 'should have a file count' do
      expect(subject.file_count).to eq file_count
    end

    it 'should have a segment description' do
      expect(subject.segment_desc).to eq segment_desc
    end
  end
end
