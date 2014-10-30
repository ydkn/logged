require 'active_support/log_subscriber'

module Logged
  module LogSubscriber
    # Shared stuff for logged log subscribers
    class Base < ::ActiveSupport::LogSubscriber
      def self.component(component)
        @component = component

        Logged.register(component, self)
      end

      def logger
        @logger ||= Logged.logger_by_component(component)
      end

      private

      %w(info debug warn error fatal unknown).each do |level|
        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{level}(event, progname = nil, &block)
            return unless logger

            progname = yield if block_given? && progname.nil?

            log_data = custom_data(event, progname)

            return unless log_data

            log_data['@event'] = event

            logger.#{level}(log_data)
          end
        METHOD
      end

      def component
        self.class.instance_variable_get('@component')
      end

      def ignore?(event, log_level = nil)
        return true unless logger
        return true unless !log_level || logger.send("#{log_level}?")

        return true if Logged.ignore?(Logged.config, event)
        return true if Logged.ignore?(Logged.config[component], event)

        false
      end

      def custom_data(event, data)
        data = Logged.custom_data(Logged.config, event, data)
        data = Logged.custom_data(Logged.config[component], event, data)

        data
      end
    end
  end
end
