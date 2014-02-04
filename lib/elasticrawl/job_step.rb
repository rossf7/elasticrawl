module Elasticrawl
  # Represents an Elastic MapReduce job flow step.  For a parse job this will
  # process a single Common Crawl segment.  For a combine job a single step
  # will aggregate the results of multiple parse jobs.
  class JobStep < ActiveRecord::Base
    belongs_to :job
    belongs_to :crawl_segment

    # Returns a custom jar step that is configured with the jar location,
    # class name and input and output paths.
    #
    # For parse jobs optionally specifies the maximum # of Common Crawl
    # data files to process before the job exits.
    def job_flow_step(job_config)
      jar = job_config['jar']
      max_files = self.job.max_files 

      step_args = []
      step_args[0] = job_config['class']
      step_args[1] = self.input_paths
      step_args[2] = self.output_path
      # All arguments must be strings.
      step_args[3] = max_files.to_s if max_files.present?

      step = Elasticity::CustomJarStep.new(jar)
      step.name = set_step_name
      step.arguments = step_args

      step
    end

  private
    # Sets the Elastic MapReduce job flow step name based on the type of job it
    # belongs to.
    def set_step_name
      case self.job.type
        when 'Elasticrawl::ParseJob'
          segment =self.crawl_segment.segment_name if self.crawl_segment.present?
          "Segment: #{segment}"
        when 'Elasticrawl::CombineJob'
          paths = self.input_paths.split(',')
          "Combining #{paths.count} jobs"
      end
    end
  end
end
