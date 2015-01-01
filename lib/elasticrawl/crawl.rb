module Elasticrawl
  # Represents a web crawl released by the Common Crawl Foundation.
  # Each crawl is split into multiple crawl segments and is stored
  # in the S3 public datasets bucket.
  class Crawl < ActiveRecord::Base
    has_many :crawl_segments

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

    # Creates crawl segments from the warc.paths file for this crawl.
    def create_segments
      file_paths = warc_paths(self.crawl_name)
      segments = parse_segments(file_paths)

      segments.keys.each do |segment_name|
        file_count = segments[segment_name]
        CrawlSegment.create_segment(self, segment_name, file_count)
      end

      segments.count
    end

    # Returns the list of segments from the database.
    def select_segments(segments_list)
      CrawlSegment.where(:segment_name => segments_list)
    end

    # Returns next # segments to be parsed. The maximum is 256
    # as this is the maximum # of steps for an Elastic MapReduce job flow.
    def next_segments(max_segments = nil)
      max_segments = Elasticrawl::MAX_SEGMENTS if max_segments.nil?
      max_segments = Elasticrawl::MAX_SEGMENTS if max_segments > Elasticrawl::MAX_SEGMENTS

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
    # Gets the WARC file paths from S3 for this crawl if it exists.
    def warc_paths(crawl_name)
      s3_path = [Elasticrawl::COMMON_CRAWL_PATH,
                 crawl_name,
                 Elasticrawl::WARC_PATHS].join('/')

      s3 = AWS::S3.new
      bucket = s3.buckets[Elasticrawl::COMMON_CRAWL_BUCKET]
      object = bucket.objects[s3_path]

      uncompress_file(object)
    end

    # Takes in a S3 object and returns the contents as an uncompressed string.
    def uncompress_file(s3_object)
      result = ''

      if s3_object.exists?
        io = StringIO.new
        io.write(s3_object.read)
        io.rewind

        gz = Zlib::GzipReader.new(io)
        result = gz.read

        gz.close
      end

      result
    end

    # Parses the segment names and file counts from the WARC file paths.
    def parse_segments(warc_paths)
      segments = Hash.new 0

      warc_paths.split.each do |warc_path|
        segment_name = warc_path.split('/')[4]
        segments[segment_name] += 1 if segment_name.present?
      end

      segments
    end
  end
end
