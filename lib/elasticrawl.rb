require 'aws-sdk'
require 'active_record'
require 'active_support'
require 'elasticity'
require 'highline/import'
require 'thor'

module Elasticrawl
  # S3 locations
  COMMON_CRAWL_BUCKET = 'aws-publicdatasets'
  COMMON_CRAWL_PATH = 'common-crawl/crawl-data'
  SEGMENTS_PATH = 'segments'
  WARC_PATHS = 'warc.paths.gz'
  MAX_SEGMENTS = 256

  require 'elasticrawl/version'

  require 'elasticrawl/config'
  require 'elasticrawl/error'

  require 'elasticrawl/cluster'
  require 'elasticrawl/crawl'
  require 'elasticrawl/crawl_segment'
  require 'elasticrawl/job'
  require 'elasticrawl/combine_job'
  require 'elasticrawl/parse_job'
  require 'elasticrawl/job_step'
end
