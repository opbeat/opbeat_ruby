# OpbeatRuby

<!-- [![Build Status](https://secure.travis-ci.org/opbeat/opbeat_ruby-ruby.png?branch=master)](http://travis-ci.org/opbeat/opbeat_ruby-ruby) -->

A client and integration layer for [Opbeat](https://opbeat.com). Forked from the [raven-ruby](https://github.com/getsentry/raven-ruby) project.


## Installation

Add the following to your `Gemfile`:

```ruby
gem "opbeat_ruby", :git => "https://github.com/opbeat/opbeat_ruby.git"
```

<!-- Or install manually
```bash
$ gem install sentry-opbeat_ruby
```
 -->
## Usage

### Rails 3

Add a `config/initializers/opbeat_ruby.rb` containing:

```ruby
require 'opbeat_ruby'

OpbeatRuby.configure do |config|
  config.project_id = '094e250818f44e82bfae13919f55fb35'
  config.access_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'
end
```

### Rails 2

No support for Rails 2 yet.

### Rack

Basic RackUp file.

```ruby
require 'opbeat_ruby'

OpbeatRuby.configure do |config|
  config.project_id = '094e250818f44e82bfae13919f55fb35'
  config.access_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'
end

use OpbeatRuby::Rack
```

### Sinatra

```ruby
require 'sinatra'
require 'opbeat_ruby'

OpbeatRuby.configure do |config|
  config.project_id = '094e250818f44e82bfae13919f55fb35'
  config.access_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'
end

use OpbeatRuby::Rack

get '/' do
  1 / 0
end
```

### Other Ruby

```ruby
require 'opbeat_ruby'

OpbeatRuby.configure do |config|
  config.project_id = '094e250818f44e82bfae13919f55fb35'
  config.access_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'

  # manually configure environment if ENV['RACK_ENV'] is not defined
  config.current_environment = 'production'
end

OpbeatRuby.capture # Global style

OpbeatRuby.capture do # Block style
  1 / 0
end
```

## Testing

```bash
$ bundle install
$ rake spec
```

## Notifications in development mode

By default events will only be sent to Opbeat if your application is running in a production environment. This is configured by default if you are running a Rack application (i.e. anytime `ENV['RACK_ENV']` is set).

You can configure Opbeat to run in non-production environments by configuring the `environments` whitelist:

```ruby
require 'opbeat_ruby'

OpbeatRuby.configure do |config|
  config.project_id = '094e250818f44e82bfae13919f55fb35'
  config.access_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'

  config.environments = %w[ development production ]
end
```

## Excluding Exceptions

If you never wish to be notified of certain exceptions, specify 'excluded_exceptions' in your config file.

In the example below, the exceptions Rails uses to generate 404 responses will be suppressed.

```ruby
require 'opbeat_ruby'

OpbeatRuby.configure do |config|
  config.project_id = '094e250818f44e82bfae13919f55fb35'
  config.access_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'

  config.excluded_exceptions = ['ActionController::RoutingError', 'ActiveRecord::RecordNotFound']
end
```

## Sanitizing Data (Processors)

If you need to sanitize or pre-process (before its sent to the server) data, you can do so using the Processors
implementation. By default, a single processor is installed (OpbeatRuby::Processors::SanitizeData), which will attempt to
sanitize keys that match various patterns (e.g. password) and values that resemble credit card numbers.

To specify your own (or to remove the defaults), simply pass them with your configuration:

```ruby
require 'opbeat_ruby'

OpbeatRuby.configure do |config|
  config.project_id = '094e250818f44e82bfae13919f55fb35'
  config.access_token = 'f0f5237a221637f561a15614f5fef218f8d6317d'

  config.processors = [OpbeatRuby::Processors::SanitizeData]
end
```

## Resources

* [Bug Tracker](http://github.com/opbeat/opbeat_ruby/issues)
* [Code](http://github.com/opbeat/opbeat_ruby)

