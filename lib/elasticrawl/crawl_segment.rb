module Elasticrawl
  # Represents a segment of a web crawl released by the Common Crawl Foundation.
  # Each segment contains archive, metadata and text files.
  class CrawlSegment < ActiveRecord::Base
    belongs_to :crawl
    has_many :job_steps

    # Description shows name and number of files in the segment.
    def segment_desc
      "Segment: #{segment_name} Files: #{file_count}"
    end

    # Creates a crawl segment based on its S3 path if it does not exist.
    def self.create_segment(crawl, segment_name, file_count)
      s3_uri = build_s3_uri(crawl.crawl_name, segment_name)

      segment = CrawlSegment.where(:crawl_id => crawl.id,
                                  :segment_name => segment_name,
                                  :segment_s3_uri => s3_uri,
                                  :file_count => file_count).first_or_create
    end

private
    # Generates the S3 location where this segment is stored.
    def self.build_s3_uri(crawl_name, segment_name)
      s3_path = ['',
                 Elasticrawl::COMMON_CRAWL_PATH,
                 crawl_name,
                 Elasticrawl::SEGMENTS_PATH,
                 segment_name,
                 '']

      URI::Generic.build(:scheme => 's3',
                         :host => Elasticrawl::COMMON_CRAWL_BUCKET,
                         :path => s3_path.join('/'))
    end
  end
end
