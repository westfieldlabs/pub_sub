# Pub/Sub

This gem encapsulates the common logic for publishing and subscribing to events from services via AWS SNS and SQS.

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
    region: 'us-east-1' # Optional: us-east-1 is default
  )
end
```

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

A service can publish & consume the same kind of message.

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

```ruby
# Example of using a message publisher with async
FooUpdate.new(Foo.first).publish(async: true)
```

### ActiveRecord integration

To automatically publish a message when its data changes, add the following to your model definition:

```ruby
class Retailer < ActiveRecord::Base
  publish_changes_with :retailer_update, async: true
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

Note you don't need any additional workers to publish, only to subscribe.

### Errors

There are two custom exceptions which may be raised during processing:

* `PubSub::MessageTypeUnknown` will be raised if a message arrives from a configured service, but is *not* in the list of acceptable messages.

### Developing with pub_sub

You must run `rake pub_sub:subscribe` once to register your personal version of the service with the queue, then you may run `rake pub_sub:poll` to start receiving messages from your own queues. The services suffix their `service_identifier` with a local identifier (your system username) so your development and test messages don't pollute the production or UAT services.

### Message design and SQS constraints

Generally it's recommended to provide the absolute minimum of data in a published message - a URI and/or ID for each event should be plenty.

The main reason for this is that SQS guarantees that every message will be received at least once. And that's _it_. You cannot rely on the order of messages, or that the same message won't be delivered n times. By relying on an API call based on ID or provided URI, which shouldn't change, we can make sure that an application gets the canonical, most up-to-date data based on a message.

## Ruby Support

* 2.2.1+
