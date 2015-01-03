class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :type
      t.string :job_name
      t.string :job_desc
      t.integer :max_files
      t.string :job_flow_id
      t.timestamps(:null => false)
    end

    add_index(:jobs, :job_name, :unique => true)
  end
end
