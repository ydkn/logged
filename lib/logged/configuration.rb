require 'active_support/ordered_options'

module Logged
  # logged configuration
  class Configuration < ::ActiveSupport::OrderedOptions
    def self.init_default_options(config, tags = true)
      config.ignore        = []
      config.tags          = [] if tags
      config.custom_ignore = nil
      config.custom_data   = nil
    end

    # Configuration for loggers
    class LoggerOptions < ::ActiveSupport::OrderedOptions
      def initialize
        Configuration.init_default_options(self, false)
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
