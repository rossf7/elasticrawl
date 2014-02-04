module Elasticrawl
  # Represents an Elastic MapReduce job flow that parses segments of
  # Common Crawl data. A job step is created per segment.
  #
  # Inherits from Job which is the ActiveRecord model class.
  class ParseJob < Job
    # Populates the job from the list of segments to be parsed.
    def set_segments(crawl_segments, max_files = nil)
      self.job_name = set_job_name
      self.job_desc = set_job_desc(crawl_segments, max_files)
      self.max_files = max_files

      crawl_segments.each do |segment|
        self.job_steps.push(create_job_step(segment))
      end
    end

    # Runs the job by calling Elastic MapReduce API.  If successful the
    # parse time is set for each segment.
    def run
      emr_config = job_config['emr_config']
      job_flow_id = run_job_flow(emr_config)

      if job_flow_id.present?
        self.job_flow_id = job_flow_id

        self.job_steps.each do |step|
          segment = step.crawl_segment
          segment.parse_time = DateTime.now
          segment.save
        end

        self.save
        self.result_message
      end
    end

    # Returns the S3 location for storing Elastic MapReduce job logs.
    def log_uri
      s3_path = "/logs/1-parse/#{self.job_name}/"
      build_s3_uri(s3_path)
    end

  private
    # Creates a job step for the crawl segment.
    def create_job_step(segment)
      JobStep.create(:job => self,
                     :crawl_segment => segment,
                     :input_paths => segment_input(segment),
                     :output_path => segment_output(segment))
    end

    # Returns the S3 location for reading a crawl segment. The input filter
    # determines which type of Common Crawl data files are parsed.
    def segment_input(segment)
      segment.segment_s3_uri + job_config['input_filter']
    end

    # Returns the S3 location for storing the step results.  This includes
    # the segment name.
    def segment_output(segment)
      job_path = "/data/1-parse/#{self.job_name}"
      s3_path = "#{job_path}/segments/#{segment.segment_name}/"
      build_s3_uri(s3_path)
    end

    # Sets the job description which forms part of the Elastic MapReduce
    # job flow name.
    def set_job_desc(segments, max_files)
      if segments.count > 0
        crawl_name = segments[0].crawl.crawl_name if segments[0].crawl.present?
        file_desc = max_files.nil? ? 'all files' : "#{max_files} files per segment"
      end

      "Crawl: #{crawl_name} Segments: #{segments.count} Parsing: #{file_desc}"
    end

    # Returns the parse job configuration from ~/.elasticrawl.jobs.yml.
    def job_config
      config = Config.new
      config.load_config('jobs')['steps']['parse']
    end
  end
end
