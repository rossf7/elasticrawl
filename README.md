# Elasticrawl

Launch AWS Elastic MapReduce jobs that process Common Crawl data.
Elasticrawl works with the latest Common Crawl data structure and file formats
([2013 data onwards](http://commoncrawl.org/new-crawl-data-available/)).
Ships with a default configuration that launches the
[elasticrawl-examples](https://github.com/rossf7/elasticrawl-examples) jobs.
This is an implementation of the standard Hadoop Word Count example.

## Overview

Common Crawl have released 2 web crawls of 2013 data. Further crawls will be released
during 2014. Each crawl is split into multiple segments that contain 3 file types.

* WARC - WARC files with the HTTP request and response for each fetch
* WAT - WARC encoded files containing JSON metadata
* WET - WARC encoded text extractions of the HTTP responses

| Crawl Name     | Date     | Segments | Pages         | Size (uncompressed) |
| -------------- |:--------:|:--------:|:-------------:|:-------------------:|
| CC-MAIN-2013-48| Nov 2013 | 517      | ~ 2.3 billion | 148 TB              |
| CC-MAIN-2013-20| May 2013 | 316      | ~ 2.0 billion | 102 TB              |

Elasticrawl is a command line tool that automates launching Elastic MapReduce
jobs against this data.

## Installation

### Dependencies

Elasticrawl is developed in Ruby and requires Ruby 1.9.3 or later.
Installing using [rbenv](https://github.com/sstephenson/rbenv#installation)
and the ruby-build plugin is recommended.

A SQLite database is used to store details of crawls and jobs. Installing the sqlite3
gem requires the development headers to be installed.

```bash

sudo yum install sqlite-devel

# OR

sudo apt-get install libsqlite3-dev

```

### Install elasticrawl

[![Gem Version](https://badge.fury.io/rb/elasticrawl.png)](http://badge.fury.io/rb/elasticrawl)
[![Code Climate](https://codeclimate.com/github/rossf7/elasticrawl.png)](https://codeclimate.com/github/rossf7/elasticrawl)
[![Build Status](https://travis-ci.org/rossf7/elasticrawl.png?branch=master)](https://travis-ci.org/rossf7/elasticrawl) 1.9.3, 2.0.0, 2.1.1

```bash
~$ gem install elasticrawl --no-rdoc --no-ri
```

If you're using rbenv you need to do a rehash to add the elasticrawl executable
to your path.

```bash
~$ rbenv rehash
```

## Quick Start

In this example you'll launch 2 EMR jobs against a small portion of the Nov
2013 crawl. Each job will take around 20 minutes to run. Most of this is setup
time while your EC2 spot instances are provisioned and your Hadoop cluster is
configured.

You'll need to have an [AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html)
to use elasticrawl. The total cost of the 2 EMR jobs will be under $1 USD.

### Setup

You'll need to choose an S3 bucket name and enter your AWS access key and
secret key. The S3 bucket will be used for storing data and logs. S3 bucket
names must be unique, using hyphens rather than underscores is recommended.

```bash
~$ elasticrawl init your-s3-bucket

Enter AWS Access Key ID: ************
Enter AWS Secret Access Key: ************

...

Bucket s3://elasticrawl-test created
Config dir /Users/ross/.elasticrawl created
Config complete
```

### Parse Job

For this example you'll parse the first 2 WET files in the first 2 segments
of the Nov 2013 crawl.

```bash
~$ elasticrawl parse CC-MAIN-2013-48 --max-segments 2 --max-files 2

Job configuration
Crawl: CC-MAIN-2013-48 Segments: 2 Parsing: 2 files per segment

Cluster configuration
Master: 1 m1.medium  (Spot: 0.12)
Core:   2 m1.medium  (Spot: 0.12)
Task:   --
Launch job? (y/n)

y
Job Name: 1391458746774 Job Flow ID: j-2X9JVDC1UKEQ1
```

You can monitor the progress of your job in the Elastic MapReduce section
of the AWS web console.

### Combine Job

The combine job will aggregate the word count results from both segments into
a single set of files.

```bash
~$ elasticrawl combine --input-jobs 1391458746774

Job configuration
Combining: 2 segments

Cluster configuration
Master: 1 m1.medium  (Spot: 0.12)
Core:   2 m1.medium  (Spot: 0.12)
Task:   --
Launch job? (y/n)

y
Job Name: 1391459918730 Job Flow ID: j-GTJ2M7D1TXO6
```

Once the combine job is complete you can download your results from the
S3 section of the AWS web console. Your data will be stored in

[your S3 bucket]/data/2-combine/[job name]

### Cleaning Up

You'll be charged by AWS for any data stored in your S3 bucket. The destroy
command deletes your S3 bucket and the ~/.elasticrawl/ directory.

```bash
~$ elasticrawl destroy

WARNING:
Bucket s3://elasticrawl-test and its data will be deleted
Config dir /home/vagrant/.elasticrawl will be deleted
Delete? (y/n)
y

Bucket s3://elasticrawl-test deleted
Config dir /home/vagrant/.elasticrawl deleted
Config deleted
```

## Configuring Elasticrawl

The elasticrawl init command creates the ~/elasticrawl/ directory which
contains

* [aws.yml](https://github.com/rossf7/elasticrawl/blob/master/templates/aws.yml) -
stores your AWS access credentials. Or you can set the environment
variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

* [cluster.yml](https://github.com/rossf7/elasticrawl/blob/master/templates/cluster.yml) -
configures the EC2 instances that are launched to form your EMR cluster

* [jobs.yml](https://github.com/rossf7/elasticrawl/blob/master/templates/jobs.yml) -
stores your S3 bucket name and the config for the parse and combine jobs

## Managing Segments

Each Common Crawl segment is parsed as a separate EMR job step. This avoids
overloading the job tracker and means if a job fails then only data from the
current segment is lost. However an EMR job flow can only contain 256 steps.
So to process an entire crawl multiple parse jobs must be combined.

```bash
~$ elasticrawl combine --input-jobs 1391430796774 1391458746774 1391498046704
```

You can use the status command to see details of crawls and jobs.

```bash
~$ elasticrawl status

Crawl Status
CC-MAIN-2013-48 Segments: to parse 517, parsed 2, total 519

Job History (last 10)
1391459918730 Launched: 2014-02-04 13:58:12 Combining: 2 segments
1391458746774 Launched: 2014-02-04 13:55:50 Crawl: CC-MAIN-2013-48 Segments: 2 Parsing: 2 files per segment
```

You can use the reset command to parse a crawl again.

```bash
~$ elasticrawl reset CC-MAIN-2013-48

Reset crawl? (y/n)
y
CC-MAIN-2013-48 Segments: to parse 519, parsed 0, total 519
```

To parse the same segments multiple times.

```bash
~$ elasticrawl parse CC-MAIN-2013-48 --segment-list 1386163036037 1386163035819 --max-files 2
```

## Running your own Jobs

1. Fork the [elasticrawl-examples](https://github.com/rossf7/elasticrawl-examples)
2. Make your changes
3. Compile your changes into a JAR using Maven
4. Upload your JAR to your own S3 bucket
5. Edit ~/.elasticrawl/jobs.yml with your JAR and class names

## TODO

* Add support for Streaming and Pig jobs

## Thanks

* Thanks to everyone at Common Crawl for making this awesome dataset available.
* Thanks to Robert Slifka for the [elasticity](https://github.com/rslifka/elasticity)
gem which provides a nice Ruby wrapper for the EMR REST API.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This code is licensed under the MIT license.
