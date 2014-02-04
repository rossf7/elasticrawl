require 'spec_helper'

describe Elasticrawl::Job do
  it { should have_many(:job_steps) }
  it { should have_db_column(:type).of_type(:string) }
  it { should have_db_column(:job_name).of_type(:string) }
  it { should have_db_column(:job_desc).of_type(:string) }
  it { should have_db_column(:max_files).of_type(:integer) }
  it { should have_db_column(:job_flow_id).of_type(:string) }
end
