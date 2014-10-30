# logged: configurable Rails logging

Logged tries to make managing logging with Rails easier.

Heavily inspired by [lograge](https://github.com/roidrage/lograge) logged allows you to log to multiple destinations
in different formats e.g. one log for view rendering times, one for requests and one for slow queries.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'logged'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install logged

## Usage

### Overview

```ruby
# config/environments/*.rb or config/application.rb
Rails.application.configure do

  # Enabling it
  config.logged.enabled = true

  # Adding a logger
  config.logged.loggers.my.logger = Logger.new(Rails.root.join('log/my.log'))

  # Enabling a component
  config.logged.action_controller.enabled = true

  # Disable Rails logging for a component
  config.logged.action_controller.disable_rails_logging = true

  # Setting log level
  config.logged.level = :debug

  # Setting the formatter
  config.logged.formatter = Logged::Formatter::JSON.new

  # Setting tags
  config.logged.tags = [ :uuid, 'my-tag' ]

  # Ignore events
  config.logged.ignore << 'process_action.action_controller'

  # Custom ignore callback
  config.logged.custom_ignore = ->(event) {
    event.duration.to_f < 0.25
  }

  # Modifying the data
  config.logged.custom_ignore = ->(event, data) {
    data.merge({ foo: :bar })
  }
end
```

### Lograge

You can replicate what lograge does by using the following configuration:

```ruby
# config/environments/*.rb or config/application.rb
Rails.application.configure do
  config.logged.enabled = true
  config.logged.action_controller.enabled = true
  config.logged.action_controller.loggers.lograge.logger = Logger.new(Rails.root.join('log/request.log'))
  config.logged.action_controller.custom_data = ->(event, data) {
    data.reject { |k, _v| %i( event filter ).include?(k) }
  }

  config.logger = Logger.new('/dev/null') # optionally discard other logging

  # to increase performance you can also add the following:
  config.log_level = :unknown
  config.logged.action_controller.disable_rails_logging = true
  config.logged.action_view.disable_rails_logging = true
  config.logged.action_mailer.disable_rails_logging = true
  config.logged.active_record.disable_rails_logging = true
end
```

## Contributing

1. Fork it ( https://github.com/ydkn/logged/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
