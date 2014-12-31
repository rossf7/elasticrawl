class AddFileCountToCrawlSegments < ActiveRecord::Migration
  def change
    add_column(:crawl_segments, :file_count, :integer)
  end
end
