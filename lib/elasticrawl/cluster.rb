module Elasticrawl
  # Configures the cluster settings for the job flow that will be launched.
  # These settings are loaded from ~/.elasticrawl/cluster.yml.
  class Cluster
    def initialize
      @master_group = instance_group('master')
      @core_group = instance_group('core')
      @task_group = instance_group('task') if has_task_group?
    end

    # Returns a configured job flow to the calling job.
    def create_job_flow(job, emr_config = nil)
      config = Config.new

      Elasticity.configure do |c|
        c.access_key = config.access_key_id
        c.secret_key = config.secret_access_key
      end

      job_flow = Elasticity::JobFlow.new
      job_flow.name = "Job: #{job.job_name} #{job.job_desc}"
      job_flow.log_uri = job.log_uri

      configure_job_flow(job_flow)
      configure_instances(job_flow)
      configure_bootstrap_actions(job_flow, emr_config)

      job_flow
    end

    # Describes the instances that will be launched.  This is used by the
    # job confirmation messages.
    def cluster_desc
      cluster_desc = <<-HERE
Cluster configuration
Master: #{instance_group_desc(@master_group)}
Core:   #{instance_group_desc(@core_group)}
Task:   #{instance_group_desc(@task_group)}
HERE
    end

  private
    # Set job flow properties from settings in cluster.yml.
    def configure_job_flow(job_flow)
        ec2_key_name = config_setting('ec2_key_name')
        placement = config_setting('placement')
        emr_ami_version = config_setting('emr_ami_version')
        job_flow_role = config_setting('job_flow_role')
        service_role = config_setting('service_role')
        ec2_subnet_id = config_setting('ec2_subnet_id')

        job_flow.ec2_subnet_id = ec2_subnet_id if ec2_subnet_id.present?
        job_flow.ec2_key_name = ec2_key_name if ec2_key_name.present?
        job_flow.placement = placement if placement.present?
        job_flow.ami_version = emr_ami_version if emr_ami_version.present?
        job_flow.job_flow_role = job_flow_role if job_flow_role.present?
        job_flow.service_role = service_role if service_role.present?
    end

    # Configures the instances that will be launched.  The master group has
    # a single node.  The task group is optional.
    def configure_instances(job_flow)
      job_flow.set_master_instance_group(@master_group)
      job_flow.set_core_instance_group(@core_group)
      job_flow.set_task_instance_group(@task_group) if @task_group.present?
    end

    # Configures bootstrap actions that will be run when each instance is
    # launched. EMR config is an XML file of Hadoop settings stored on S3.
    # There are applied to each node by a bootstrap action.
    def configure_bootstrap_actions(job_flow, emr_config = nil)
      bootstrap_scripts = config_setting('bootstrap_scripts')

      if bootstrap_scripts.present?
        bootstrap_scripts.each do |script_uri|
          action = Elasticity::BootstrapAction.new(script_uri, '', '')
          job_flow.add_bootstrap_action(action)
        end
      end

      if emr_config.present?
        action = Elasticity::HadoopFileBootstrapAction.new(emr_config)
        job_flow.add_bootstrap_action(action)
      end
    end

    # Returns whether cluster.yml specifies a task group.
    def has_task_group?
      task_config = config_for_group('task')
      task_config.has_key?('instance_count') && task_config['instance_count'] > 0
    end

    # Describes an instance group.
    def instance_group_desc(group)
      if group.present?
        if group.market == 'SPOT'
          price = "(Spot: #{group.bid_price})"
        else
          price = '(On Demand)'
        end

        "#{group.count} #{group.type}  #{price}"
      else
        '--'
      end
    end

    # Configures an instance group with the instance type, # of instances and
    # the bid price if spot instances are to be used.
    def instance_group(group_name)
      config = config_for_group(group_name)

      instance_group = Elasticity::InstanceGroup.new
      instance_group.role = group_name.upcase
      instance_group.type = config['instance_type']

      if config.has_key?('instance_count') && config['instance_count'] > 0
        instance_group.count = config['instance_count']
      end

      if config['use_spot_instances'] == true
        instance_group.set_spot_instances(config['bid_price'])
      end

      instance_group
    end

    # Returns the config settings for an instance group.
    def config_for_group(group_name)
      config_setting("#{group_name}_instance_group")
    end

    # Returns a config setting from cluster.yml.
    def config_setting(key_name)
      config = Config.new
      config.load_config('cluster')[key_name]
    end
  end
end
