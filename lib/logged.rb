require 'logged/version'
require 'logged/level_conversion'
require 'logged/logger'
require 'logged/formatter/raw'
require 'logged/formatter/key_value'
require 'logged/formatter/json'
require 'logged/formatter/single_key'
require 'logged/formatter/logstash'
require 'logged/railtie'
require 'logged/rack/logger'
require 'logged/subscriptions'

# logged
module Logged
  extend Logged::LevelConversion
  extend Logged::Subscriptions

  # special keys which not represent a component
  CONFIG_KEYS = Configuration::DEFAULT_VALUES.keys + [:loggers, :disable_rails_logging]

  mattr_accessor :app, :config

  class << self
    # setup logged
    def setup(app)
      self.app    = app
      self.config = app.config.logged

      app.config.middleware.insert_after ::Rails::Rack::Logger, Logged::Rack::Logger

      setup_components
    end

    # default log level
    def default_level
      config.level || :info
    end

    # default log formatter
    def default_formatter
      config.formatter || (@default_formatter ||= Logged::Formatter::KeyValue.new)
    end

    # logger wrapper for component
    def logger_by_component(component)
      return nil unless config.enabled

      key = "component_#{component}"

      return @component_loggers[key] if @component_loggers.key?(key)

      loggers = loggers_for(component)

      if loggers.blank?
        @component_loggers[key] = nil

        return nil
      end

      formatter = config[component].formatter || default_formatter

      @component_loggers[key] = Logger.new(loggers, component, formatter)
    end
    alias_method :'[]', :logger_by_component

    # loggers for component
    def loggers_for(component)
      loggers_from_config(config)
        .merge(loggers_from_config(config[component]))
    end

    # loggers from config level
    def loggers_from_config(conf)
      loggers = {}

      return loggers unless conf.enabled

      conf.loggers.each do |name, c|
        logger, options = load_logger(name, c)

        next unless logger && options

        loggers[logger] = options
      end

      loggers
    end

    # load logger from configuration
    def load_logger(name, conf)
      return [nil, nil] unless conf.enabled

      options = conf.dup
      options[:name] = name

      logger = options.delete(:logger)

      logger = Rails.logger if logger == :rails

      return [nil, nil] unless logger

      [logger, options]
    end

    # configure and enable component
    def enable_component(component)
      loggers = loggers_for(component)

      return unless loggers.any?

      loggers.each do |logger, options|
        level = options[:level] || config[component].level || default_level

        logger.level = level_to_const(level) if logger.respond_to?(:'level=')
      end

      # only attach subscribers with loggers
      @subscribers[component].each do |subscriber|
        subscriber.attach_to(component)
      end
    end

    # check if event should be ignored
    def ignore?(conf, event)
      return false unless event
      return false unless conf.enabled

      return true if !event.is_a?(String) && conf.ignore.is_a?(Array) && conf.ignore.include?(event.name)

      return conf.custom_ignore.call(event) if conf.custom_ignore.respond_to?(:call)

      false
    end

    # run data callbacks
    def custom_data(conf, event, data)
      return data unless conf.enabled
      return data unless conf.custom_data.respond_to?(:call)

      conf.custom_data.call(event, data)
    end

    # configured components
    def components
      config.keys - CONFIG_KEYS
    end

    # rack request environment
    def request_env
      Thread.current[:logged_request_env]
    end

    private

    def setup_components
      components.each do |component|
        remove_rails_subscriber(component) if config[component].disable_rails_logging

        next unless config[component].enabled

        enable_component(component)
      end
    end

    def init
      @subscribers       ||= Hash.new { |hash, key| hash[key] = [] }
      @component_loggers   = {}

      require_rails_subscribers
    end
  end

  init
end
