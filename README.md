# Elasticrawl

Command line tool for launching Hadoop jobs using AWS EMR (Elastic MapReduce) to process Common Crawl data.
Elasticrawl can be used with [crawl data](http://commoncrawl.org/the-data/get-started/) from April 2014 onwards.

| Crawl Name     | Month     | Web Pages
| -------------- |:--------:|:--------:|
| [CC-MAIN-2014-15](http://blog.commoncrawl.org/2014/07/april-2014-crawl-data-available/) | April 2014 | ~ 2.3 billion
| [CC-MAIN-2014-23](http://blog.commoncrawl.org/2014/08/july-2014-crawl-data-available/) | July 2014 | ~ 3.6 billion
| [CC-MAIN-2014-35](http://blog.commoncrawl.org/2014/09/august-2014-crawl-data-available/) | August 2014 | ~ 2.8 billion
| [CC-MAIN-2014-49](http://blog.commoncrawl.org/2014/12/november-2014-crawl-archive-available/) | November 2014 | ~ 1.95 billion

Common Crawl announce new crawls on their [blog](http://blog.commoncrawl.org/).

Ships with a default configuration that launches the
[elasticrawl-examples](https://github.com/rossf7/elasticrawl-examples) jobs.
This is an implementation of the standard Hadoop Word Count example.

This [blog post](https://rossfairbanks.com/2015/01/03/parsing-common-crawl-using-elasticrawl.html) has a walkthrough of running the example jobs on the November 2014 crawl.

## Installation

Deployment packages are available for Linux and OS X, unfortunately Windows isn't supported yet. Download the package, extract it and run the elasticrawl command from the package directory.

```bash
# OS X            https://d2ujrnticqzebc.cloudfront.net/elasticrawl-1.1.1-osx.tar.gz
# Linux (64-bit)  https://d2ujrnticqzebc.cloudfront.net/elasticrawl-1.1.1-linux-x86_64.tar.gz
# Linux (32-bit)  https://d2ujrnticqzebc.cloudfront.net/elasticrawl-1.1.1-linux-x86.tar.gz

# e.g.

curl -O https://d2ujrnticqzebc.cloudfront.net/elasticrawl-1.1.1-osx.tar.gz
tar -xzf elasticrawl-1.1.1-osx.tar.gz
cd elasticrawl-1.1.1-osx/
./elasticrawl --help
```

## Commands

### elasticrawl init

The init command takes in an S3 bucket name and your AWS credentials. The S3 bucket will be created
and will store your data and logs.

```bash
~$ ./elasticrawl init your-s3-bucket

Enter AWS Access Key ID: ************
Enter AWS Secret Access Key: ************

...

Bucket s3://elasticrawl-test created
Config dir /Users/ross/.elasticrawl created
Config complete
```

### elasticrawl parse

The parse command takes in the crawl name and an optional number of segments and files to parse.

```bash
~$ ./elasticrawl parse CC-MAIN-2014-49 --max-segments 2 --max-files 3
Segments
Segment: 1416400372202.67 Files: 150
Segment: 1416400372490.23 Files: 124

Job configuration
Crawl: CC-MAIN-2014-49 Segments: 2 Parsing: 3 files per segment

Cluster configuration
Master: 1 m1.medium  (Spot: 0.12)
Core:   2 m1.medium  (Spot: 0.12)
Task:   --
Launch job? (y/n)
y

Job: 1420124830792 Job Flow ID: j-2R3MFE6TWLIUB
```

### elasticrawl combine

The combine command takes in the results of previous parse jobs and produces a combined set of results.

```bash
~$ ./elasticrawl combine --input-jobs 1420124830792
Job configuration
Combining: 2 segments

Cluster configuration
Master: 1 m1.medium  (Spot: 0.12)
Core:   2 m1.medium  (Spot: 0.12)
Task:   --
Launch job? (y/n)
y

Job: 1420129496115 Job Flow ID: j-251GXDIZGK8HL
```

### elasticrawl status

The status command shows crawls and your job history.

```bash
~$ ./elasticrawl status
Crawl Status
CC-MAIN-2014-49 Segments: to parse 134, parsed 2, total 136

Job History (last 10)
1420124830792 Launched: 2015-01-01 15:07:10 Crawl: CC-MAIN-2014-49 Segments: 2 Parsing: 3 files per segment
```

### elasticrawl reset

The reset comment resets a crawl so it is parsed again.

```bash
~$ ./elasticrawl reset CC-MAIN-2014-49
Reset crawl? (y/n)
y
 CC-MAIN-2014-49 Segments: to parse 136, parsed 0, total 136
```

### elasticrawl destroy

The destroy command deletes your S3 bucket and the ~/.elasticrawl directory.

```bash
~$ ./elasticrawl destroy

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

* [aws.yml](https://github.com/rossf7/.elasticrawl/blob/master/templates/aws.yml) -
stores your AWS access credentials. Or you can set the environment
variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

* [cluster.yml](https://github.com/rossf7/elasticrawl/blob/master/templates/cluster.yml) -
configures the EC2 instances that are launched to form your EMR cluster

* [jobs.yml](https://github.com/rossf7/elasticrawl/blob/master/templates/jobs.yml) -
stores your S3 bucket name and the config for the parse and combine jobs

## Development

Elasticrawl is developed in Ruby and requires Ruby 1.9.3 or later (Ruby 2.1 is recommended). The sqlite3 and nokogiri gems have C extensions which mean you may need to install development headers.

[![Gem Version](https://badge.fury.io/rb/elasticrawl.png)](http://badge.fury.io/rb/elasticrawl)
[![Code Climate](https://codeclimate.com/github/rossf7/elasticrawl.png)](https://codeclimate.com/github/rossf7/elasticrawl)
[![Build Status](https://travis-ci.org/rossf7/elasticrawl.png?branch=master)](https://travis-ci.org/rossf7/elasticrawl) 1.9.3, 2.0.0, 2.1.5, 2.2.0

The deployment packages are created using [Traveling Ruby](http://phusion.github.io/traveling-ruby/). The deploy packages contain a Ruby 2.1 interpreter, Gems and the compiled C extensions. The [traveling-elasticrawl](https://github.com/rossf7/traveling-elasticrawl) repository has a Rake task that automates building the deployment packages.

## TODO

* Add support for Streaming and Pig jobs

## Thanks

* Thanks to everyone at Common Crawl for making this awesome dataset available!
* Thanks to Robert Slifka for the [elasticity](https://github.com/rslifka/elasticity)
gem which provides a nice Ruby wrapper for the EMR REST API.
* Thanks to Phusion for creating Traveling Ruby.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This code is licensed under the MIT license.
