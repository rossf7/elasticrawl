module Elasticrawl
  # Represents an Elastic MapReduce job flow that combines the results of
  # multiple Elasticrawl Parse jobs.  Parse jobs write their results per
  # segment. Combine jobs aggregate parse results into a single set of files.
  #
  # Inherits from Job which is the ActiveRecord model class.
  class CombineJob < Job
    # Takes in an array of parse jobs that are to be combined. Creates a single
    # job step whose input paths are the outputs of the parse jobs.
    def set_input_jobs(input_jobs)
      segment_count = 0
      input_paths = []

      input_jobs.each do |job_name|
        input_job = Job.where(:job_name => job_name,
                              :type => 'Elasticrawl::ParseJob').first_or_initialize
        step_count = input_job.job_steps.count

        if step_count > 0
          segment_count += step_count
          input_paths << set_input_path(input_job)
        end
      end

      self.job_name = set_job_name
      self.job_desc = set_job_desc(segment_count)
      job_steps.push(create_job_step(input_paths.join(',')))
    end

    # Runs the job by calling the Elastic MapReduce API.
    def run
      emr_config = job_config['emr_config']
      job_flow_id = run_job_flow(emr_config)

      if job_flow_id.present?
        self.job_flow_id = job_flow_id
        self.save
        self.result_message
      end
    end

    # Returns the S3 location for storing Elastic MapReduce job logs.
    def log_uri
      s3_path = "/logs/2-combine/#{self.job_name}/"
      build_s3_uri(s3_path)
    end

  private
    # Returns a single job step.  The input paths are a CSV list of parse
    # job outputs.
    def create_job_step(input_paths)
      JobStep.create(:job => self,
                     :input_paths => input_paths,
                     :output_path => set_output_path)
    end

    # Returns the S3 location for reading a parse job. A wildcard is
    # used for the segment names. The input filter depends on the output
    # file type of the parse job and what type of compression is used.
    def set_input_path(input_job)
      job_name = input_job.job_name
      input_filter = job_config['input_filter']

      s3_path = "/data/1-parse/#{job_name}/segments/*/#{input_filter}"
      build_s3_uri(s3_path)
    end

    # Returns the S3 location for storing the combine job results.
    def set_output_path
      s3_path = "/data/2-combine/#{self.job_name}/"
      build_s3_uri(s3_path)
    end

    # Sets the job description which forms part of the Elastic MapReduce
    # job flow name.
    def set_job_desc(segment_count)
      "Combining: #{segment_count} segments"
    end

    # Returns the combine job configuration from ~/.elasticrawl.jobs.yml.
    def job_config
      config = Config.new
      config.load_config('jobs')['steps']['combine']
    end
  end
end
