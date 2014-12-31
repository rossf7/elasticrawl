require 'spec_helper'

describe Elasticrawl::CrawlSegment do
  it { should belong_to(:crawl) }
  it { should have_many(:job_steps) }
  it { should have_db_column(:segment_name).of_type(:string) }
  it { should have_db_column(:segment_s3_uri).of_type(:string) }
  it { should have_db_column(:parse_time).of_type(:datetime) }
  it { should have_db_column(:file_count).of_type(:integer) }

  describe '#initialize' do
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2013-20') }
    subject { crawl.crawl_segments[0]}

    before do
      crawl.create_segments
    end

    it 'should have a segment name' do
      expect(subject.segment_name).to eq '1368696381249'
    end

    it 'should have an s3 uri' do
      expect(subject.segment_s3_uri).to eq \
        's3://aws-publicdatasets/common-crawl/crawl-data/CC-MAIN-2013-20/segments/1368696381249/'
    end
  end
end
