# Opbeat

[![Build Status](https://secure.travis-ci.org/opbeat/opbeat_ruby.png?branch=master)](http://travis-ci.org/opbeat/opbeat_ruby)

A client and integration layer for [Opbeat](https://opbeat.com). Forked from the [raven-ruby](https://github.com/getsentry/raven-ruby) project.


## Installation

Add the following to your `Gemfile`:

```ruby
gem "opbeat"
```

## Usage

### Rails 3 and Rails 4

Add a `config/initializers/opbeat.rb` containing:

```ruby
require 'opbeat'

Opbeat.configure do |config|
  config.organization_id = '094e250818f44e82bfae13919f55fb35'
  config.app_id = '094e250818'
  config.secret_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'
end
```

### Rails 2

No support for Rails 2 yet.

### Rack

Basic RackUp file.

```ruby
require 'opbeat'

use Opbeat::Rack

Opbeat.configure do |config|
  config.organization_id = '094e250818f44e82bfae13919f55fb35'
  config.app_id = '094e250818'
  config.secret_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'
end

```

### Sinatra

```ruby
require 'sinatra'
require 'opbeat'

use Opbeat::Rack

Opbeat.configure do |config|
  config.organization_id = '094e250818f44e82bfae13919f55fb35'
  config.app_id = '094e250818'
  config.secret_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'
end

get '/' do
  1 / 0
end
```

### Other Ruby

```ruby
require 'opbeat'

Opbeat.configure do |config|
  config.organization_id = '094e250818f44e82bfae13919f55fb35'
  config.app_id = '094e250818'
  config.secret_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'

  # manually configure environment if ENV['RACK_ENV'] is not defined
  config.current_environment = 'production'
end

Opbeat.capture # Global style

Opbeat.capture do # Block style
  1 / 0
end
```

## Background processing

With [delayed_job](https://github.com/collectiveidea/delayed_job) and [sidekiq](http://sidekiq.org/), Opbeat will automatically pick up exceptions that are raised in background jobs. 

To enable Opbeat for [resque](https://github.com/resque/resque), add the following (for example in `config/initializers/opbeat.rb`):

```ruby
require "resque/failure/multiple"
require "opbeat/integrations/resque"

Resque::Failure::Multiple.classes = [Resque::Failure::Opbeat]
Resque::Failure.backend = Resque::Failure::Multiple
```

## Explicitly notifying Opbeat

It is possible to explicitely notify Opbeat. In the case of a simple message:
```
Opbeat.captureMessage("Not happy with the way things turned out")
```

If you want to catch and explicitely send an exception to Opbeat, this is the way to do it:
```
begin
  faultyCall
rescue Exception => e
  Opbeat.captureException(e)
```

Both `Opbeat.captureException` and `Opbeat.captureMessage` take additional `options`:
```ruby
Opbeat.captureMessage("Device registration error", :extra => {:device_id => my_device_id})
```


## Notifications in development mode

By default events will be sent to Opbeat if your application is running in any of the following environments: `development`, `production`, `default`. Environment is set by default if you are running a Rack application (i.e. anytime `ENV['RACK_ENV']` is set).

You can configure Opbeat to run only in production environments by configuring the `environments` whitelist:

```ruby
require 'opbeat'

Opbeat.configure do |config|
  config.organization_id = '094e250818f44e82bfae13919f55fb35'
  config.app_id = '094e250818'
  config.secret_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'

  config.environments = %w[ production ]
end
```

## Excluding Exceptions

If you never wish to be notified of certain exceptions, specify 'excluded_exceptions' in your config file.

In the example below, the exceptions Rails uses to generate 404 responses will be suppressed.

```ruby
require 'opbeat'

Opbeat.configure do |config|
  config.organization_id = '094e250818f44e82bfae13919f55fb35'
  config.app_id = '094e250818'
  config.secret_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'

  config.excluded_exceptions = ['ActionController::RoutingError', 'ActiveRecord::RecordNotFound']
end
```

## Sanitizing Data (Processors)

If you need to sanitize or pre-process (before its sent to the server) data, you can do so using the Processors
implementation. By default, a single processor is installed (Opbeat::Processors::SanitizeData), which will attempt to
sanitize keys that match various patterns (e.g. password) and values that resemble credit card numbers.

To specify your own (or to remove the defaults), simply pass them with your configuration:

```ruby
require 'opbeat'

Opbeat.configure do |config|
  config.organization_id = '094e250818f44e82bfae13919f55fb35'
  config.app_id = '094e250818'
  config.secret_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'
  
  config.processors = [Opbeat::Processor::SanitizeData]
end
```

## User information

With Rails, Opbeat expects `controller#current_user` to return an object with `id`, `email` and/or `username` attributes. You can change the name of the current user method in the following manner:

```ruby
Opbeat.configure do |config|
  ...

  config.user_controller_method = "my_other_user_method"
end
```

Opbeat will now call `controller#my_other_user_method` to retrieve the user object.

## Setting context

It is possible to set a context which be included an exceptions that are captured.

```ruby
Opbeat.set_context :extra => {:device_id => my_device_id}
Opbeat.sendMessage("Hello world")  # will include the context
end
```


## Testing

```bash
$ bundle install
$ rake spec
```


## Resources

* [Bug Tracker](http://github.com/opbeat/opbeat_ruby/issues)
* [Code](http://github.com/opbeat/opbeat_ruby)

