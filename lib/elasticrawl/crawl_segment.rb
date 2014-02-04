module Elasticrawl
  # Represents a segment of a web crawl released by the Common Crawl Foundation.
  # Each segment contains archive, metadata and text files.
  class CrawlSegment < ActiveRecord::Base
    belongs_to :crawl
    has_many :job_steps
  end
end
