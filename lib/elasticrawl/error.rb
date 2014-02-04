module Elasticrawl
  # Base error class extends standard error.
  class Error < StandardError; end

  # AWS access credentials are invalid.
  class AWSCredentialsInvalidError < Error; end

  # Config directory does not exist.
  class ConfigDirMissingError < Error; end

  # Database error accessing sqlite database.
  class DatabaseAccessError < Error; end

  # Error accessing AWS Elastic MapReduce API.
  class ElasticMapReduceAccessError < Error; end

  # Error accessing config directory.
  class FileAccessError < Error; end

  # Error accessing AWS S3 API.
  class S3AccessError < Error; end
end
