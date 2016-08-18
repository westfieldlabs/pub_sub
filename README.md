# Pub/Sub

This gem encapsulates the common logic for publishing and subscribing to events from services via AWS SNS and SQS.

It relies on https://github.com/pedro/cb2 and hence redis to circuit break in case of problems with AWS.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pub_sub', github: 'westfield/pub_sub'

```

And then execute:

```sh
$ bundle
```

## Usage

### Configuration
Configuration is handled with an initializer as below.

```ruby
# config/initializers/pub_sub.rb
PubSub.configure do |config|
  # The name of this service. Topics and queues will be named foo-service-[env].
  config.service 'foo'

  # Listen for the specified messages from one or more services
  config.subscribe_to 'barbaz', messages: ['bar_update', 'baz_update']
  config.subscribe_to 'wibble', messages: ['wibble_update']

  # Credentials and region for Amazon AWS (for SNS/SQS)
  config.aws(
    key: 'mykey',
    secret: 'my_secret',
    regions: ['us-east-1', 'us-west-1']
  )
end
```
If you use standard AWS environment variables (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`), then you do not need to specify them here.

Similarly, if you want to subscribe in all available regions, then omit the `regions` parameter as well.

### Logging
If running under Rails, this will log to Rails.logger. In other environments, you can set the logger like `PubSub.config.logger = MyLogger` or similar.

### Wiring up subscriptions
To connect queues to topics, and put the above config file into practice, you should run `bundle exec rake pub_sub:subscribe`. Verify this has worked as expected by running `bundle exec rake pub_sub:debug:subscriptions`.
Note that the subscribe task will be run automatically before the poll task, so it's probably not needed to run the subscribe task on production or staging. Checking that the subscriptions are correct after a deploy would be prudent, of course.

### Subscriber workers
You can set the number of worker threads for the subscribers with the ENV variable 'PUB_SUB_WORKER_CONCURRENCY'. By default it's two; testing with Standard 1X dynos on heroku suggests around 10-20 is reasonable, depending on the application.

### Unsubscribing
This functionality is not implemented yet.

### Receiving a message

When PubSub receives a message, it performs a couple of checks before processing:

* If the message originates from a known service, but the message type is not in the list of accepted types for that service, a `PubSub::MessageTypeUnknown` exception will be logged & raised.

If the message passes those validations, it will `classify` the message type and run its `process` method. Data from the message is available inside the message handler via the `data` variable.

```ruby
# app/events/foo_update.rb
require 'open-uri'

class FooUpdate
  include PubSub::MessageHandler

  # Recieve & process an foo_update message
  def self.process(data)
    foo = Foo.find_or_initialize_by(id: data['id'])
    foo_name = JSON.parse(open(data['uri']).read)['data']['name']
    foo.update(name: foo_name)
  end
end

```

### Publishing a message

A message publisher requires two things - an include of `PubSub::MessagePublisher` and a `message_data` method.

Note: If `message_data` is not defined in your publisher, a `NotImplementedError` will be raised.

```ruby
# app/events/foo_update.rb
class FooUpdate
  include PubSub::MessagePublisher

  def initialize(foo)
    @foo = foo
  end

  def message_data
    { url: foo_url, id: @foo.id }
  end

  def foo_url
    "https://example.com/foos/#{@foo.id}"
  end
end
```

### Combined Publisher / Receiver

A service can publish & consume the same kind of message. This can be used to offload heavy processing from the web tier, like resque or activejob.

```ruby
# app/events/foo_update.rb
require 'open-uri'

class FooUpdate
  include PubSub::MessagePublisher
  include PubSub::MessageHandler

  # Recieve & process an foo_update message
  def self.process(data)
    foo = Foo.find_or_initialize_by(id: data['id'])
    foo_name = JSON.parse(open(data['uri']).read)['data']['name']
    foo.update(name: foo_name)
  end

  def initialize(foo)
    @foo = foo
  end

  def message_data
    { url: foo_url, id: @foo.id }
  end

  def foo_url
    "https://example.com/foos/#{@foo.id}"
  end
end
```

### Async
`MessagePublisher.publish` has an optional parameter `async` which will send the message in a separate thread. This avoids blocking when communicating with the Amazon SNS service which generally adds a delay of around 0.5-2 seconds. This can cause slow response times for `POST` and `PUT` requests.

The trade-off is that if a message fails to send for some reason, it won't fail the parent transaction and you won't be notified. For this reason `async` is off by default, but you can use it where it makes sense to.

It is not recommended to use async functionality - it is deprecated and liekly to be removed soon. Instead, consider using futures from git@github.com:ruby-concurrency/concurrent-ruby.git .

```ruby
# Example of using a message publisher with async
FooUpdate.new(Foo.first).publish(async: true)
```

### ActiveRecord integration

To automatically publish a message when its data changes, add the following to your model definition:

```ruby
class Retailer < ActiveRecord::Base
  publish_changes_with :retailer_update
end
```

### Rake tasks

There are a few rake tasks made available for working with the message queues and subscriptions.

* `rake pub_sub:subscribe` - will subscribe the service to the message queues specified in the config. You must run this at least once as it registers your service with the queue.
* `rake pub_sub:poll` - starts receiving messages from the queue(s) and dispatching them to the appropriate handler(s) if available. It is multi-threaded with 2 threads by default, but this can be changed by setting the `PUB_SUB_WORKER_CONCURRENCY` environment variable. This can't be run until after `pub_sub:subscribe` has been run.
* `rake pub_sub:debug:all` - prints out information about the state of queues, topics & subscriptions.
* `rake pub_sub:debug:queues` - prints out information about the state of queues including the approximate number of messages in the queue.
* `rake pub_sub:debug:subscriptions` - prints out information about the state of subscriptions.
* `rake pub_sub:debug:topics` - prints out information about the state of topics.

If hosting on Heroku your `Procfile` ought to include a line like

```
worker: bundle exec rake pub_sub:poll
```

Note you don't need this line to publish, only to subscribe.

### Errors

There is a custom exception which may be raised during processing:

* `PubSub::MessageTypeUnknown` will be raised if a message arrives from a configured service, but is *not* in the list of acceptable messages.

### Region failover

In case of problems in one AWS region, this gem will attempt to failover across regions. By default, the regions selected are us-east-1, then us-west-1, then eu-west-1, then ap-southeast-1. An assumption is made that if SNS is encountering problems in a region, it's probable that SQS will as well, so errors in a region from either service will contribute to the failover circuit breaking logic.

The subscriber will "region hop" periodically if it's queue is empty even in the abscence of errors. This is because if an application doesn't publish, it will never know that SNS is having problems. By effectively receiving messages on _any_ region, we avoid this failure mode.

### Developing with pub_sub

Run `rake pub_sub:poll` to start receiving messages from your own queues. The services suffix their `service_identifier` with a local identifier (your system username) so your development and test messages don't pollute the production or UAT services.

To see how the subscriptions look without necessarily sending events through them, you can `rake pub_sub:subscribe` once to register your personal version of the service's queues with the topics. This may be useful for understanding how messages will flow, in conjunction with `rake pub_sub:debug:subscriptions`.

### Message design and SQS constraints

Generally it's recommended to provide the absolute minimum of data in a published message - a URI and/or ID for each event should be plenty.

The main reason for this is that SQS guarantees that every message will be received at least once. And that's _it_. You cannot rely on the order of messages, or that the same message won't be delivered n times. By relying on an API call based on ID or provided URI, which shouldn't change, we can make sure that an application gets the canonical, most up-to-date data based on a message.

It's possible to enforce ordering in application logic (eg, have a message counter that always increases, and compare counts to detect ordering issues and/or duplicates), but this gem does not implement such logic.

## Ruby Support

* 2.2.1+
* JRuby 9.0.0.0+
