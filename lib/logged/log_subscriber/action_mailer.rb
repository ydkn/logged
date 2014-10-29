require 'logged/log_subscriber/base'

module Logged
  module LogSubscriber
    # Log subscriber for ActionMailer events
    class ActionMailer < Base
      component :action_mailer

      # An email was delivered.
      def deliver(event)
        return if ignore?(event, :debug)

        process_duration = Thread.current[:logged_action_mailer_process_duration] || 0.0

        data = {
          event:    event.name,
          duration: (process_duration + event.duration.to_f).round(2)
        }

        data.merge!(extract_mail_deliver(event.payload))

        Thread.current[:logged_action_mailer_process_duration] = nil

        debug(event, data)
      end

      # An email was received.
      def receive(event)
        return unless logger.debug?
        return if ignore?(event)

        data = {
          event:    event.name,
          duration: event.duration.to_f.round(2)
        }

        debug(event, data)
      end

      # An email was generated.
      def process(event)
        payload = event.payload

        Thread.current[:logged_action_mailer_process_mailer]   = payload[:mailer]
        Thread.current[:logged_action_mailer_process_action]   = payload[:action]
        Thread.current[:logged_action_mailer_process_duration] = event.duration.to_f
      end

      private

      def extract_mail_deliver(payload)
        data = {
          mailer:     (payload[:mailer] || Thread.current[:logged_action_mailer_process_mailer]),
          action:     (payload[:action] || Thread.current[:logged_action_mailer_process_action]),
          from:       Array(payload[:from]).join(', '),
          to:         Array(payload[:to]).join(', '),
          bcc:        Array(payload[:bcc]).join(', ')
        }

        Thread.current[:logged_action_mailer_process_mailer] = nil
        Thread.current[:logged_action_mailer_process_action] = nil

        data
      end
    end
  end
end
