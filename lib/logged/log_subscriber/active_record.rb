require 'active_record/log_subscriber'
require 'logged/log_subscriber/base'

module Logged
  module LogSubscriber
    # Log subscriber for ActiveRecord events
    class ActiveRecord < Base
      # This query types will be ignored
      IGNORE_PAYLOAD_NAMES = %w( SCHEMA EXPLAIN )

      component :active_record

      def sql(event)
        return if ignore?(event, :debug)

        payload = event.payload

        return if IGNORE_PAYLOAD_NAMES.include?(payload[:name])

        data = {
          event:    event.name,
          name:     payload[:name].presence,
          sql:      payload[:sql],
          duration: event.duration.to_f.round(2)
        }

        debug(event, data)
      end
    end
  end
end
