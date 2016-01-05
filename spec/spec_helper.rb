require 'elasticrawl'
require 'rspec'
require 'database_cleaner'
require 'shoulda-matchers'

RSpec.configure do |config|
  # Run each test in a transaction and rollback data on completion.
  DatabaseCleaner.strategy = :transaction

  # Use Shoulda matchers for schema tests.
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)

  config.before(:each) do
    # Stub S3 call to get WARC file paths
    warc_paths = IO.read(File.join(File.dirname(__FILE__), 'fixtures', 'warc.paths'))
    allow_any_instance_of(Elasticrawl::Crawl).to receive(:warc_paths).and_return(warc_paths)

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
