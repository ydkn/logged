require 'action_view/log_subscriber'
require 'logged/log_subscriber/base'

module Logged
  module LogSubscriber
    # Log subscriber for ActionView events
    class ActionView < Base
      component :action_view

      def render_template(event)
        return if ignore?(event, :debug)

        payload = event.payload

        data = {
          event:    event.name,
          view:     from_rails_root(payload[:identifier]),
          layout:   from_rails_root(payload[:layout]),
          duration: event.duration.to_f.round(2)
        }.reject { |_k, v| v.blank? }

        debug(event, data)
      end
      alias_method :render_partial, :render_template
      alias_method :render_collection, :render_template

      protected

      def from_rails_root(string)
        return nil if string.blank?

        string = string.sub(rails_root, ::ActionView::LogSubscriber::EMPTY)
        string.sub!(::ActionView::LogSubscriber::VIEWS_PATTERN, ::ActionView::LogSubscriber::EMPTY)
        string
      end

      def rails_root
        @root ||= "#{::Rails.root}/"
      end
    end
  end
end
