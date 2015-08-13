module Logged
  # Railtie for logged
  module Subscriptions
    # remove rails log subscriber by component name
    def remove_rails_subscriber(component)
      subscriber = rails_subscriber(component)

      return unless subscriber

      unsubscribe(component, subscriber)
    end

    # try to guess and get rails log subscriber by component name
    def rails_subscriber(component)
      class_name = "::#{component.to_s.camelize}::LogSubscriber"

      return unless Object.const_defined?(class_name)

      clazz = class_name.constantize

      ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
        return subscriber if subscriber.is_a?(clazz)
      end

      nil
    end

    # unsubscribe a subscriber from a component
    def unsubscribe(component, subscriber)
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
    def register(component, subscriber)
      return if @subscribers[component].include?(subscriber)

      @subscribers[component] << subscriber
    end

    # require log subscribers for rails frameworks
    def require_rails_subscribers
      require 'logged/log_subscriber/action_controller' if defined?(ActionController)
      require 'logged/log_subscriber/action_view'       if defined?(ActionView)
      require 'logged/log_subscriber/active_record'     if defined?(ActiveRecord)
      require 'logged/log_subscriber/action_mailer'     if defined?(ActionMailer)
    end
  end
end
