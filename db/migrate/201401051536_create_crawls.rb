class CreateCrawls < ActiveRecord::Migration
  def change
    create_table :crawls do |t|
      t.string :crawl_name
      t.timestamps(:null => false)
    end

    add_index(:crawls, :crawl_name, :unique => true)
  end
end
