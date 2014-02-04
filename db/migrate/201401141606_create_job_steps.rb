class CreateJobSteps < ActiveRecord::Migration
  def change
    create_table :job_steps do |t|
      t.references :job
      t.references :crawl_segment
      t.text :input_paths
      t.text :output_path
      t.timestamps
    end
  end
end
