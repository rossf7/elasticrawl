class CreateCrawlSegments < ActiveRecord::Migration
  def change
    create_table :crawl_segments do |t|
      t.references :crawl
      t.string :segment_name
      t.string :segment_s3_uri
      t.datetime :parse_time
      t.timestamps
    end

    add_index(:crawl_segments, :segment_name, :unique => true)
    add_index(:crawl_segments, :segment_s3_uri, :unique => true)
  end
end
