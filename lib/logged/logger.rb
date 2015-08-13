require 'logger'
require 'logged/tagged_logging'

module Logged
  # Logger wrapping a component
  class Logger
    include TaggedLogging

    attr_reader :loggers, :component

    def initialize(loggers, component, formatter)
      @loggers   = loggers
      @component = component
      @formatter = formatter
      @enabled   = true
    end

    def add(severity, message = nil, progname = nil)
      return unless enabled?

      message = yield    if block_given? && message.blank?
      message = progname if message.blank?

      data, event = extract_data_and_event(message)

      return if data.blank?

      level = Logged.level_to_sym(severity)

      @loggers.each do |logger, options|
        next unless logger.send("#{level}?")

        add_to_logger(level, event, data, logger, options)
      end
    end
    alias_method :log, :add

    %w(info debug warn error fatal unknown).each do |level|
      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{level}?
          @loggers.keys.any? { |l| l.#{level}? }
        end

        def #{level}(progname = nil, &block)
          add(::Logger::#{level.upcase}, nil, progname, &block)
        end
      METHOD
    end

    def close
      @loggers.keys.each do |logger|
        logger.close if logger.respond_to?(:close)
      end
    end

    def datetime_format; end

    def datetime_format=(_format); end

    def <<(_msg); end

    def enabled?
      @enabled
    end

    def enabled=(enable)
      @enabled = !!enable
    end

    def enable!
      self.enabled = true
    end

    def disable!
      self.enabled = false
    end

    private

    def prepare_data(event, data, options)
      config = Logged.config[component].loggers[options[:name]]

      return nil if Logged.ignore?(config, event)

      Logged.custom_data(config, event, data)
    end

    def add_to_logger(level, event, data, logger, options)
      data = prepare_data(event, data, options)

      return if data.blank?

      formatter = options[:formatter] || @formatter

      msg = formatter.call(data)

      return if msg.blank?

      log_data(logger, level, msg)
    end

    def log_data(logger, level, msg)
      if logger.respond_to?(:tagged)
        logger.tagged(*current_tags) do
          logger.send(level, msg)
        end
      else
        logger.send(level, msg)
      end
    end

    def extract_data_and_event(message)
      return if message.blank?

      message = { message: message } if message.is_a?(String)

      event = message.delete('@event')

      message = Logged.custom_data(Logged.config, event, message)
      return [nil, nil] if message.blank?

      message = Logged.custom_data(Logged.config[component], event, message)
      return [nil, nil] if message.blank?

      [message, event]
    end
  end
end
