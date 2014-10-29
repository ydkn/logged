require 'uri'
require 'logged/log_subscriber/base'

module Logged
  module LogSubscriber
    # Log subscriber for ActionController events
    class ActionController < Base
      component :action_controller

      def process_action(event)
        return if ignore?(event, :info)

        payload = event.payload

        data = {
          event: event.name
        }

        data.merge!(extract_request(payload))
        data.merge!(cached_event_data)
        data.merge!(extract_path(payload))
        data.merge!(extract_status(payload))
        data.merge!(extract_runtimes(payload))

        data[:duration] = event.duration.to_f.round(2)

        info(event, data)
      end

      def redirect_to(event)
        Thread.current[:logged_action_controller_location] = event.payload[:location]
      end

      def halted_callback(event)
        Thread.current[:logged_action_controller_filter] = event.payload[:filter]
      end

      private

      def extract_request(payload)
        {
          method:     payload[:method].to_sym,
          format:     payload[:format],
          controller: payload[:params]['controller'],
          action:     payload[:params]['action']
        }.reject { |_k, v| v.blank? }
      end

      def extract_path(payload)
        uri = URI.parse(payload[:path])

        { path: uri.path }
      end

      def extract_status(payload)
        status = payload[:status]
        error  = payload[:exception]

        if status
          { status: status.to_i }
        elsif error
          exception, message = error

          { status: 500, error: "#{exception}:#{message}" }
        else
          { status: 0 }
        end
      end

      def extract_runtimes(payload)
        view_runtime, db_runtime = nil

        view_runtime = payload[:view_runtime].to_f.round(2) if payload.key?(:view_runtime)
        db_runtime   = payload[:db_runtime].to_f.round(2)   if payload.key?(:db_runtime)

        {
          view_runtime: view_runtime,
          db_runtime: db_runtime
        }.reject { |_k, v| v.blank? }
      end

      def cached_event_data
        location = Thread.current[:logged_action_controller_location]
        Thread.current[:logged_action_controller_location] = nil

        filter = Thread.current[:logged_action_controller_filter]
        Thread.current[:logged_action_controller_filter] = nil

        {
          location: location,
          filter:   filter
        }.reject { |_k, v| v.blank? }
      end
    end
  end
end
