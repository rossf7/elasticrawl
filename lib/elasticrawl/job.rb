module Elasticrawl
  # The base job class that is extended by ParseJob and CombineJob.
  class Job < ActiveRecord::Base
    has_many :job_steps

    # Displays a confirmation message showing the configuration of the
    # Elastic MapReduce job flow and cluster.
    def confirm_message
      cluster = Cluster.new

      case self.type
      when 'Elasticrawl::ParseJob'
        message = segment_list
      else
        message = []
      end

      message.push('Job configuration')
      message.push(self.job_desc)
      message.push('')
      message.push(cluster.cluster_desc)

      message.join("\n")
    end

    # Displays the Job Name and Elastic MapReduce Job Flow ID if the job was
    # launched successfully.
    def result_message
      "\nJob Name: #{self.job_name} Job Flow ID: #{self.job_flow_id}"
    end

    # Displays the history of the current job. Called by the status command.
    def history
      launch_time = "Launched: #{self.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
      "#{self.job_name} #{launch_time} #{self.job_desc}"
    end

  protected
    # Calls the Elastic MapReduce API to create a Job Flow. Returns the Job Flow ID.
    def run_job_flow(emr_config)
      cluster = Cluster.new
      job_flow = cluster.create_job_flow(self, emr_config)

      job_steps.each do |step|
        job_flow.add_step(step.job_flow_step(job_config))
      end

      begin
        job_flow.run

      rescue StandardError => e
        raise ElasticMapReduceAccessError, e.message
      end
    end

    # Returns an S3 location for storing either data or logs.
    def build_s3_uri(s3_path)
      URI::Generic.build(:scheme => 's3',
                         :host => bucket_name,
                         :path => s3_path).to_s
    end

    # Returns the S3 bucket name configured by the user using the init command.
    def bucket_name
      config = Config.new
      config.load_config('jobs')['s3_bucket_name']
    end

    # Sets the job name which is the current Unix timestamp in milliseconds.
    # This is the same naming format used for Common Crawl segment names.
    def set_job_name
      (Time.now.to_f * 1000).to_i.to_s
    end
  end
end
