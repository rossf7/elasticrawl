require 'spec_helper'

describe Elasticrawl::Cluster do
  describe '#create_job_flow' do
    let(:crawl) { Elasticrawl::Crawl.create(:crawl_name => 'CC-MAIN-2014-49') }
    let(:job) { Elasticrawl::ParseJob.new }
    let(:cluster) { Elasticrawl::Cluster.new }
    subject { cluster.create_job_flow(job) }

    before do
      job.set_segments(crawl.crawl_segments)
    end

    it 'should be an Elasticity::JobFlow' do
      expect(subject).to be_a Elasticity::JobFlow
    end

    it 'should have a job flow name' do
      expect(subject.name).to eq "Job Name: #{job.job_name} #{job.job_desc}"
    end

    it 'should have a log uri' do
      expect(subject.log_uri).to eq job.log_uri
    end

    it 'should have an ec2 key name' do
      expect(subject.ec2_key_name).to eq 'elasticrawl'
    end

    it 'should have a placement az name' do
      expect(subject.placement).to eq 'us-east-1c'
    end

    it 'should have an ami version' do
      expect(subject.ami_version).to eq 'latest'
    end
  end

  describe '#cluster_desc' do
    let(:cluster_desc) {
      cluster_desc = <<-HERE
Cluster configuration
Master: 1 m1.medium  (Spot: 0.12)
Core:   2 m1.medium  (Spot: 0.12)
Task:   --
      HERE
    }
    subject { Elasticrawl::Cluster.new } 

    it 'should describe configured instance groups' do
      expect(subject.cluster_desc).to eq cluster_desc
    end
  end
end
