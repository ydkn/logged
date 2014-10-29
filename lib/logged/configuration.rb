require 'active_support/ordered_options'

module Logged
  # logged configuration
  class Configuration < ::ActiveSupport::OrderedOptions
    DEFAULT_VALUES = {
      enabled:       false,
      level:         nil,
      formatter:     nil,
      ignore:        -> { [] },
      tags:          -> { [] },
      custom_ignore: nil,
      custom_data:   nil
    }

    def self.init_default_options(config, ignore_defaults = [])
      DEFAULT_VALUES.each do |key, value|
        next if ignore_defaults.include?(key)

        if value.is_a?(Proc)
          config[key] = value.call
        else
          config[key] = value
        end
      end
    end

    # Configuration for loggers
    class LoggerOptions < ::ActiveSupport::OrderedOptions
      def initialize
        Configuration.init_default_options(self, [:tags])

        self.enabled = true
      end
    end

    # Configuration for components
    class ComponentOptions < ::ActiveSupport::OrderedOptions
      def initialize
        Configuration.init_default_options(self)

        self.loggers = ::ActiveSupport::OrderedOptions.new { |hash, key| hash[key] = LoggerOptions.new }
      end
    end

    def initialize
      super { |hash, key| hash[key] = ComponentOptions.new }

      Configuration.init_default_options(self)

      self.loggers = ::ActiveSupport::OrderedOptions.new { |hash, key| hash[key] = LoggerOptions.new }
    end
  end
end
