require 'elasticrawl'
require 'rspec'
require 'database_cleaner'
require 'shoulda-matchers'

RSpec.configure do |config|
  # Run each test in a transaction and rollback data on completion.
  DatabaseCleaner.strategy = :transaction

  config.before(:each) do
    # Return S3 paths that are used to create a crawl object with 3 crawl segments.
    segment_paths = []
    segment_paths[0] = 'common-crawl/crawl-data/CC-MAIN-2013-20/segments/1368696381249/'
    segment_paths[1] = 'common-crawl/crawl-data/CC-MAIN-2013-20/segments/1368696381630/'
    segment_paths[2] = 'common-crawl/crawl-data/CC-MAIN-2013-20/segments/1368696382185/'

    allow_any_instance_of(Elasticrawl::Crawl).to receive(:s3_segment_paths).and_return(segment_paths)

    # Load config from spec/fixtures/ rather than ~/.elasticrawl/
    config_dir = File.join(File.dirname(__FILE__), 'fixtures')
    allow_any_instance_of(Elasticrawl::Config).to receive(:config_dir).and_return(config_dir)

    # Load sqlite database. For testing this is stored at db/elasticrawl.sqlite3
    config = Elasticrawl::Config.new
    config.load_database

    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
