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

# logged
module Logged
  extend Logged::LevelConversion

  # special keys which not represent a component
  CONFIG_KEYS = Configuration::DEFAULT_VALUES.keys + [:loggers, :disable_rails_logging]

  mattr_accessor :app, :config

  # setup logged
  def self.setup(app)
    self.app    = app
    self.config = app.config.logged

    app.config.middleware.insert_after ::Rails::Rack::Logger, Logged::Rack::Logger

    components.each do |component|
      remove_rails_subscriber(component) if config[component].disable_rails_logging

      next unless config[component].enabled

      enable_component(component)
    end
  end

  # default log level
  def self.default_level
    config.level || :info
  end

  # default log formatter
  def self.default_formatter
    config.formatter || (@default_formatter ||= Logged::Formatter::KeyValue.new)
  end

  # logger wrapper for component
  def self.logger_by_component(component)
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

  # loggers for component
  def self.loggers_for(component)
    loggers_from_config(config)
      .merge(loggers_from_config(config[component]))
  end

  def self.[](component)
    loggers_for(component)
  end

  # loggers from config level
  def self.loggers_from_config(conf)
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
  def self.load_logger(name, conf)
    return [nil, nil] unless conf.enabled

    options = conf.dup
    options[:name] = name

    logger = options.delete(:logger)

    logger = Rails.logger if logger == :rails

    return [nil, nil] unless logger

    [logger, options]
  end

  # configure and enable component
  def self.enable_component(component)
    loggers = loggers_for(component)

    loggers.each do |logger, options|
      level = options[:level] || config[component].level || default_level

      logger.level = level_to_const(level) if logger.respond_to?(:'level=')
    end

    # only attach subscribers with loggers
    if loggers.any?
      @subscribers[component].each do |subscriber|
        subscriber.attach_to(component)
      end
    end
  end

  # check if event should be ignored
  def self.ignore?(conf, event)
    return false unless event
    return false unless conf.enabled

    if !event.is_a?(String) && conf.ignore.is_a?(Array)
      return true if conf.ignore.include?(event.name)
    end

    if conf.custom_ignore.respond_to?(:call)
      return conf.custom_ignore.call(event)
    end

    false
  end

  # run data callbacks
  def self.custom_data(conf, event, data)
    return data unless conf.enabled
    return data unless conf.custom_data.respond_to?(:call)

    conf.custom_data.call(event, data)
  end

  # configured components
  def self.components
    config.keys - CONFIG_KEYS
  end

  # remove rails log subscriber by component name
  def self.remove_rails_subscriber(component)
    subscriber = rails_subscriber(component)

    return unless subscriber

    unsubscribe(component, subscriber)
  end

  # try to guess and get rails log subscriber by component name
  def self.rails_subscriber(component)
    class_name = "::#{component.to_s.camelize}::LogSubscriber"

    return unless Object.const_defined?(class_name)

    clazz = class_name.constantize

    ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
      return subscriber if subscriber.is_a?(clazz)
    end

    nil
  end

  # unsubscribe a subscriber from a component
  def self.unsubscribe(component, subscriber)
    events = subscriber.public_methods(false).reject { |method| method.to_s == 'call' }

    events.each do |event|
      ActiveSupport::Notifications.notifier.listeners_for("#{event}.#{component}").each do |listener|
        if listener.instance_variable_get('@delegate') == subscriber
          ActiveSupport::Notifications.unsubscribe listener
        end
      end
    end
  end

  # register log subscriber with logged
  def self.register(component, subscriber)
    return if @subscribers[component].include?(subscriber)

    @subscribers[component] << subscriber
  end

  def self.request_env
    Thread.current[:logged_request_env]
  end

  private

  def self.init
    @subscribers ||= Hash.new { |hash, key| hash[key] = [] }

    @component_loggers = {}
  end

  init
end

require 'logged/log_subscriber/action_controller' if defined?(ActionController)
require 'logged/log_subscriber/action_view'       if defined?(ActionView)
require 'logged/log_subscriber/active_record'     if defined?(ActiveRecord)
require 'logged/log_subscriber/action_mailer'     if defined?(ActionMailer)
