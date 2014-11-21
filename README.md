Amazon Kinesis Client Library for Ruby
======================================

This gem provides an interface to the KCL MultiLangDaemon, which is part of the [Amazon Kinesis Client Library](https://github.com/awslabs/amazon-kinesis-client). This interface manages the interaction with the MultiLangDaemon so that developers can focus on implementing their record processor executable. A record processor executable typically looks something like:

```ruby
class SimpleProcessor
  include RecordProcessor

  def process_records records, checkpointer
    # process records and checkpoint
  end
end
```

Note, the initial implementation of this gem is largely based on the reference [python implementation](https://github.com/awslabs/amazon-kinesis-client-python) provided by Amazon.


Environment Setup
-----------------

Please ensure the following environment requirements are reviewed before using the gem:
- make sure that your environment is configured to allow the Amazon Kinesis Client Library to use your [AWS Security Credentials](http://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html). By default the *DefaultAWSCredentialsProviderChain* is configured so you'll want to make your credentials available to one of the credentials providers in that provider chain. There are several ways to do this such as providing a ~/.aws/credentials file, or specifying the *AWS_ACCESS_KEY_ID* and
*AWS_SECRET_ACCESS_KEY* environment variables.
- ensure **JAVA** is available in the environment. This gem works by invoking the packaged *amazon-kinesis-client.jar* and which subsequently executes the target ruby record processor, therefore a compatible JVM/JDK is therefore required.


Environment Variables
---------------------
- **AWS_ACCESS_KEY_ID** : AWS credential for accessing the target kinesis queue
- **AWS_SECRET_ACCESS_KEY** : AWS credential for accessing the target kinesis queue
- **APP_NAME** : Used by the KCL as the name of this application. It is used as the DynamoDB table name created by KCL to store checkpoints.
- **PATH_TO_JAVA** : (optional) custom java executable path (by default `which java` is used).


Example Consumer Client Setup
-----------------------------

Firstly please create the ruby script to run your kinesis consumer with structure similar to the following:

```ruby
# FILE_NAME: run_simple_kinesis_client.rb

require 'kcl'

# define a record processor
class SimpleProcessor < Kcl::AdvancedRecordProcessor
  def process_record data
    p data
  end
end

# config the executor
Kcl::Executor.new do |executor|
  executor.config stream_name: 'data-kinesis-queue',
                  application_name: 'RubyKCLSample',
                  max_records: 5,
                  idle_time_between_reads_in_millis: 500

  # setup the target record processor
  executor.record_processor do
    SimpleProcessor.new
  end
end

# execute and run
Kcl::Executor.run
```

The most essential part of this is the `Kcl::Executor.run` bit, which is required in the script that you want the consumer client to run. The configuration (i.e. `Kcl::Executor.new` bit) and record processor class (i.e. `SimpleProcessor`) can be put in other suitable places.

Next, run the script with an additional argument `exec`, e.g. `ruby run_simple_kinesis_client.rb exec`. Please note, it will **not** work without the `exec` argument, because the script is intent to be invoked by the amazon-kinesis-client java process. Specifying `exec` actually triggers the java consumer process.

The following shows an example of how the consumer worker can be specified in the Procfile:

```bash
worker: bundle exec <your_consumer_client_script> exec
```


Configurations
--------------

The properties required by the MultiLangDaemon (please refer to [**this**](https://github.com/awslabs/amazon-kinesis-client-python/blob/master/samples/sample.properties)) can be configured through the `executor.config`. That is:


```ruby
Kcl::Executor.new do |executor|
  executor.config stream_name: 'data-kinesis-queue',
                  application_name: 'RubyKCLSample',
                  max_records: 5,
                  idle_time_between_reads_in_millis: 500,
                  region_name: 'us-east-1',
                  initial_position_in_stream: 'TRIM_HORIZON'

  #.....
end
```

Under the hood, the Kcl gem will translate it to the proper java properties file for the java process. Please try to use underscore key name (i.e. `stream_name` for `streamName`), so it follows good ruby convention.

Please ensure the following configuration values are specified:
- **stream_name** : the target kinesis queue name
- **application_name** : it is not required if the environment variable **APP_NAME** is set.


Record Processors
-----------------

Please also specify the record processor for the `Kcl::Executor`, i.e.

```ruby
Kcl::Executor.new do |executor|
  #.......
  executor.record_processor do
    YourProcessor.new
  end
end
```

The reason that why `SimpleProcessor.new` is initialised in the block instead of:

```ruby
executor.record_processor SimpleProcessor.new
```

is that processor should only get instantiated when invoked by the consumer client java process, and not in the first `<client_script> exec` call.


### Kcl::RecordProcessor

The RecordProcessor module offers the most basic interface to implement a record processor. The following shows a simple example:

```ruby
require 'kcl'

class YourProcessor
  include Kcl::RecordProcessor

  def init shared_id
    # Called once by a KCLProcess before any calls to process_records
  end

  def process_records records, checkpointer
    # Called by a KCLProcess with a list of records to be processed and a
    # checkpointer which accepts sequence numbers from the records to indicate
    # where in the stream to checkpoint.
  end

  def shutdown checkpointer, reason
    #Called by a KCLProcess instance to indicate that this record processor
    # should shutdown. After this is called, there will be no more calls to
    # any other methods of this record processor.
  end
end
```

Please note, with the basic `Kcl::RecordProcessor`, it is the client's responsibility to manage the checkpoints. The client are free to decide how often the checkpoint should be made through doing:

```ruby
def process_records records, checkpointer
  checkpointer.checkpoint records.last['sequenceNumber']
end
```

### Kcl::AdvancedRecordProcessor

The AdvancedRecordProcessor class take cares the basic checkpoint logic, and the clients only required to implement the `process_record` method, for example:

```ruby
require 'kcl'

class YourProcessor < Kcl::AdvancedRecordProcessor
  def initialize
    super sleep_seconds: 10, # default to 5
          checkpoint_retries: 10, # default to 5
          checkpoint_freq_seconds: 30 # default to 60
  end

  def process_record record
    data = record[:data]
    partition_key = record[:partition_key]
    sequence_number = record[:sequence_number]

    # do something with data
  end
end

```


Downloading
-----------
install stable releases with the following command:

```bash
gem install amazon-kinesis-client-ruby
```

The development version (hosted on Github) can be installed with:

```bash
git clone git@github.com:everydayhero/amazon-kinesis-client-ruby.git
cd amazon-kinesis-client-ruby
rake install
```

###Run Tests
```bash
rake spec
```


Future Roadmap
--------------
- dependency management for the Amazon kinesis client jar files by utilising [ruby-maven](https://github.com/mkristian/ruby-maven) (potentially).


Contributing
------------

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request
