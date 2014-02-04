module Elasticrawl
  # Represents a web crawl released by the Common Crawl Foundation.
  # Each crawl is split into multiple crawl segments and is stored
  # in the S3 public datasets bucket.
  class Crawl < ActiveRecord::Base
    has_many :crawl_segments

    COMMON_CRAWL_BUCKET = 'aws-publicdatasets'
    COMMON_CRAWL_PATH = 'common-crawl/crawl-data/'
    SEGMENTS_PATH = '/segments/'
    MAX_SEGMENTS = 256

    # Returns the status of all saved crawls and the current job history.
    def self.status(show_all = false)
      status = ['Crawl Status']
      Crawl.all.map { |crawl| status << crawl.status }

      if show_all == true
        header = 'Job History'
        jobs = Job.where('job_flow_id is not null').order(:id => :desc)
      else
        header = 'Job History (last 10)'
        jobs = Job.where('job_flow_id is not null').order(:id => :desc).limit(10)
      end

      status << ['', header]
      jobs.map { |job| status << job.history }

      status.join("\n")
    end

    # Returns the status of the current crawl.
    def status
      total = self.crawl_segments.count
      remaining = CrawlSegment.where(:crawl_id => self.id,
                                        :parse_time => nil).count
      parsed = total - remaining
      status = self.crawl_name
      status += " Segments: to parse #{remaining}, "
      status += "parsed #{parsed}, total #{total}"
    end

    # Checks for crawl segments in the database.  If none are found then checks
    # the S3 API and creates any segments that are found.
    def has_segments?
      if self.crawl_segments.count == 0
        segment_count = create_segments
        result = segment_count > 0
      else
        result = true
      end
    end

    # Creates crawl segments from their S3 paths and returns the segment count.
    def create_segments
      segment_paths = s3_segment_paths(self.crawl_name)
      save if segment_paths.count > 0
      segment_paths.map { |s3_path| create_segment(s3_path) }

      segment_paths.count
    end

    # Returns the list of segments from the database.
    def select_segments(segments_list)
      CrawlSegment.where(:segment_name => segments_list)
    end

    # Returns next # segments to be parsed. The maximum is 256
    # as this is the maximum # of steps for an Elastic MapReduce job flow.
    def next_segments(max_segments = nil)
      max_segments = MAX_SEGMENTS if max_segments.nil?
      max_segments = MAX_SEGMENTS if max_segments > MAX_SEGMENTS

      self.crawl_segments.where(:parse_time => nil).limit(max_segments)
    end

    # Resets parse time of all parsed segments to null so they will be parsed
    # again. Returns the updated crawl status.
    def reset
      segments = CrawlSegment.where('crawl_id = ? and parse_time is not null',
                                    self.id)
      segments.map { |segment| segment.update_attribute(:parse_time, nil) }

      status
    end

  private
    # Creates a crawl segment based on its S3 path if it does not exist.
    def create_segment(s3_path)
      segment_name = s3_path.split('/').last
      segment_s3_uri = URI::Generic.build(:scheme => 's3',
                                          :host => COMMON_CRAWL_BUCKET,
                                          :path => "/#{s3_path}").to_s

      segment = CrawlSegment.where(:crawl_id => self.id,
                         :segment_name => segment_name,
                         :segment_s3_uri => segment_s3_uri).first_or_create
    end

    # Returns a list of S3 paths for the crawl name.
    def s3_segment_paths(crawl_name)
      s3_segment_tree(crawl_name).children.collect(&:prefix)
    end

    # Calls the S3 API and returns the tree structure for the crawl name.
    def s3_segment_tree(crawl_name)
      crawl_path = [COMMON_CRAWL_PATH, crawl_name, SEGMENTS_PATH].join

      s3 = AWS::S3.new
      bucket = s3.buckets[COMMON_CRAWL_BUCKET]
      bucket.as_tree(:prefix => crawl_path)
    end
  end
end
