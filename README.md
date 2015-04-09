# Pub/Sub

This gem encapsulates the common logic for broadcasting and subscribing to events from services.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pub_sub', git: "https://#{github_auth}@github.com/westfield/pub_sub.git"

```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pub_sub

## Usage

### Configuration
Configuration is handled with an initializer as below.

```ruby
# config/initializers/pub_sub.rb
PubSub.configure do |config|
  # The name of this service
  config.service :event

  # Amazon AWS credentials
  config.aws.access_key_id = 'abc123'
  config.aws.aws_secret_access_key = 'abc123456zyx'
  config.aws.region = 'us-east-1' # Optional: us-east-1 is default

  # Listen for messages from one or more services
  config.subscribe_to! :store, :centre
  # or
  # config.subscribe_to! :store
  # config.subscribe_to! :centre
end
```


### Receiving a message

PubSub will look for a handler class based on the name of the message. For example, if a message is received with the type `retailer_update`, it will look for the class `RetailerUpdate` with the method `process`. If a matching handler cannot be found, the message will be skipped.

Message data is available as a hash with indifferent access within the handler with `data` variable.

```ruby
# app/events/retailer_update.rb
class RetailerUpdate < PubSub::EventHandler
  def process
  	retailer = Retailer.find_or_initialize_by(retailer_id: data.id)
	retailer.update(name: data.name)
  end
end

```


### Publishing a message

Publishing a message is fairly simple. Your publisher must inherit from `PubSub::EventPublisher` and call the `publish!` method with the data you want to send.

The `type` and `origin` metadata will be added automatically.

```ruby
# app/events/event_update.rb
class EventUpdate < PubSub::EventPublisher
  def publish!(event)
    super(url: event_url(event), id: event.id)
  end

  def event_url(event)
    "https://example.com/event/#{event.id}"
  end
end
```


### Rake tasks

There are a few rake tasks made available for working with the message queues and subscriptions.

* `rake pub_sub:poll` - this task will receive messages from the queue(s) and dispatch them to the appropriate handler if one can be found. It is multi-threaded with 2 threads by default, but this can be changed by setting the `WORKER_CONCURRENCY` environment variable.

* `rake pub_sub:subscribe` - this task will subscribe the service to the message queues specified in the config.

* `rake pub_sub:debug` - this will print out information about the state of queues, topics & subscriptions.
