require 'spec_helper'
require 'logged'
require 'active_support/notifications'
require 'active_support/log_subscriber'
require 'action_controller/log_subscriber'
require 'action_view/log_subscriber'
require 'action_mailer/log_subscriber'
require 'active_record/log_subscriber'

RSpec.describe Logged do
  context 'when removing Rails log subscribers' do
    after do
      log_subscribers = []

      ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
        events = subscriber.public_methods(false).reject { |method| method.to_s == 'call' }
        events.each do |event|
          ActiveSupport::Notifications.notifier.listeners_for("#{event}.#{subscriber.class.to_s.split('::').first.underscore}").each do |listener|
            delegate = listener.instance_variable_get('@delegate')
            log_subscribers << subscriber.class if delegate == subscriber
          end
        end
      end

      ActionController::LogSubscriber.attach_to :action_controller unless log_subscribers.include?(ActionController::LogSubscriber)
      ActionView::LogSubscriber.attach_to :action_view unless log_subscribers.include?(ActionView::LogSubscriber)
      ActionMailer::LogSubscriber.attach_to :action_mailer unless log_subscribers.include?(ActionMailer::LogSubscriber)
      ActiveRecord::LogSubscriber.attach_to :active_record unless log_subscribers.include?(ActiveRecord::LogSubscriber)
    end

    it 'removes subscribers for action_controller events' do
      expect {
        Logged.remove_rails_subscriber(:action_controller)
      }.to change {
        ActiveSupport::Notifications.notifier.listeners_for('process_action.action_controller')
      }
    end

    it 'removes subscribers for action_view events' do
      expect {
        Logged.remove_rails_subscriber(:action_view)
      }.to change {
        ActiveSupport::Notifications.notifier.listeners_for('render_template.action_view')
      }
    end

    it 'removes subscribers for action_mailer events' do
      expect {
        Logged.remove_rails_subscriber(:action_mailer)
      }.to change {
        ActiveSupport::Notifications.notifier.listeners_for('deliver.action_mailer')
      }
    end

    it 'removes subscribers for active_record events' do
      expect {
        Logged.remove_rails_subscriber(:active_record)
      }.to change {
        ActiveSupport::Notifications.notifier.listeners_for('sql.active_record')
      }
    end
  end
end
