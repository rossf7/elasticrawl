module Elasticrawl
  # Represents the current configuration which is persisted to
  # ~/.elasticrawl/ and contains 3 configuration files.
  # 
  # aws.yml     - AWS access credentials unless stored in the environment
  #               variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
  # cluster.yml - Elastic MapReduce cluster config including instance groups.
  # jobs.yml    - Elastic MapReduce jobs config and the S3 bucket used for
  #               storing data and logs.
  #
  # This directory also contains the Elasticrawl SQLite database.
  class Config
    CONFIG_DIR = '.elasticrawl'
    DATABASE_FILE = 'elasticrawl.sqlite3'
    TEMPLATES_DIR = '../../templates'
    TEMPLATE_FILES = ['aws.yml', 'cluster.yml', 'jobs.yml']

    attr_reader :access_key_id
    attr_reader :secret_access_key

    # Sets the AWS access credentials needed for the S3 and EMR API calls.
    def initialize(access_key_id = nil, secret_access_key = nil)
      # Credentials have been provided to the init command.
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key

      # If credentials are not set then check if they are available in aws.yml.
      if dir_exists?
        config = load_config('aws')
        key = config['access_key_id']
        secret = config['secret_access_key']

        @access_key_id ||= key unless key == 'ACCESS_KEY_ID'
        @secret_access_key ||= secret unless secret == 'SECRET_ACCESS_KEY'
      end

      # If credentials are still not set then check AWS environment variables.
      @access_key_id ||= ENV['AWS_ACCESS_KEY_ID']
      @secret_access_key ||= ENV['AWS_SECRET_ACCESS_KEY']

      # Set AWS credentials for use when accessing the S3 API.
      AWS.config(:access_key_id => @access_key_id,
                 :secret_access_key => @secret_access_key)
    end

    # Returns the location of the config directory.
    def config_dir
      File.join(Dir.home, CONFIG_DIR)
    end

    # Checks if the configuration directory exists.
    def dir_exists?
      Dir.exists?(config_dir)
    end

    # Loads a YAML configuration file.
    def load_config(config_file)
      if dir_exists?
        begin
          config_file = File.join(config_dir, "#{config_file}.yml")
          config = YAML::load(File.open(config_file))

        rescue StandardError => e
          raise FileAccessError, e.message
        end
      else
        raise ConfigDirMissingError, 'Config dir missing. Run init command'
      end
    end

    # Loads the sqlite database.  If no database exists it will be created
    # and the database migrations will be run.
    def load_database
      if dir_exists?
        config = {
          'adapter' => 'sqlite3',
          'database' => File.join(config_dir, DATABASE_FILE),
          'pool' => 5,
          'timeout' => 5000
        }

        begin
          ActiveRecord::Base.establish_connection(config)
          ActiveRecord::Migrator.migrate(File.join(File.dirname(__FILE__), \
            '../../db/migrate'), ENV['VERSION'] ? ENV['VERSION'].to_i : nil )

        rescue StandardError => e
          raise DatabaseAccessError, e.message
        end
      else
        raise ConfigDirMissingError, 'Config dir missing. Run init command'
      end
    end

    # Checks if a S3 bucket name is in use.
    def bucket_exists?(bucket_name)
      begin
        s3 = AWS::S3.new
        s3.buckets[bucket_name].exists?

      rescue AWS::S3::Errors::SignatureDoesNotMatch => e
        raise AWSCredentialsInvalidError, 'AWS access credentials are invalid'
      rescue AWS::Errors::Base => s3e
        raise S3AccessError.new(s3e.http_response), e.message
      end
    end

    # Creates the S3 bucket and config directory. Deploys the config templates
    # and creates the sqlite database.
    def create(bucket_name)
      create_bucket(bucket_name)
      deploy_templates(bucket_name)
      load_database

      status_message(bucket_name, 'created')
    end

    # Deletes the S3 bucket and config directory.
    def delete
      bucket_name = load_config('jobs')['s3_bucket_name']
      delete_bucket(bucket_name)
      delete_config_dir
      
      status_message(bucket_name, 'deleted')
    end

    # Displayed by destroy command to confirm deletion.
    def delete_warning
      bucket_name = load_config('jobs')['s3_bucket_name']

      message = ['WARNING:']
      message << "Bucket s3://#{bucket_name} and its data will be deleted"
      message << "Config dir #{config_dir} will be deleted"

      message.join("\n")
    end

    # Displayed by init command.
    def access_key_prompt
      prompt = "Enter AWS Access Key ID:"
      prompt += " [#{@access_key_id}]" if @access_key_id.present?

      prompt
    end

    # Displayed by init command.
    def secret_key_prompt
      prompt = "Enter AWS Secret Access Key:"
      prompt += " [#{@secret_access_key}]" if @secret_access_key.present?

      prompt
    end

  private
    # Creates a bucket using the S3 API.
    def create_bucket(bucket_name)
      begin
        s3 = AWS::S3.new
        s3.buckets.create(bucket_name)

      rescue AWS::Errors::Base => s3e
        raise S3AccessError.new(s3e.http_response), e.message
      end
    end

    # Deletes a bucket and its contents using the S3 API.
    def delete_bucket(bucket_name)
      begin
        s3 = AWS::S3.new
        bucket = s3.buckets[bucket_name]
        bucket.delete!

      rescue AWS::Errors::Base => s3e
        raise S3AccessError.new(s3e.http_response), e.message
      end
    end

    # Creates config directory and copies config templates into it.
    # Saves S3 bucket name to jobs.yml and AWS credentials to aws.yml.
    def deploy_templates(bucket_name)
      begin
        Dir.mkdir(config_dir, 0755) if dir_exists? == false

        TEMPLATE_FILES.each do |template_file|
          FileUtils.cp(File.join(File.dirname(__FILE__), TEMPLATES_DIR, template_file),
                       File.join(config_dir, template_file))
        end

        save_config('jobs', { 'BUCKET_NAME' => bucket_name })
        save_aws_config

      rescue StandardError => e
        raise FileAccessError, e.message
      end
    end

    # Saves AWS access credentials to aws.yml unless they are configured as
    # environment variables.
    def save_aws_config
      env_key = ENV['AWS_ACCESS_KEY_ID']
      env_secret = ENV['AWS_SECRET_ACCESS_KEY']

      creds = {}
      creds['ACCESS_KEY_ID'] = @access_key_id unless @access_key_id == env_key
      creds['SECRET_ACCESS_KEY'] = @secret_access_key \
        unless @secret_access_key == env_secret

      save_config('aws', creds)
    end

    # Saves config values by overwriting placeholder values in template.
    def save_config(template, params)
      config_file = File.join(config_dir, "#{template}.yml")
      config = File.read(config_file)

      params.map { |key, value| config = config.gsub(key, value) }

      File.open(config_file, 'w') { |file| file.write(config) }
    end

    # Deletes the config directory including its contents.
    def delete_config_dir
      begin
        FileUtils.rm_r(config_dir) if dir_exists?

      rescue StandardError => e
        raise FileAccessError, e.message
      end
    end

    # Notifies user of results of init or destroy commands.
    def status_message(bucket_name, state)
      message = ['', "Bucket s3://#{bucket_name} #{state}"]
      message << "Config dir #{config_dir} #{state}"

      state = 'complete' if state == 'created'
      message << "Config #{state}"

      message.join("\n")
    end
  end
end
