require 'active_support'
require 'action_dispatch/http/request'

module Logged
  module Rack
    # Handle tagged logging much like Rails::Rack::Logger
    class Logger
      def initialize(app)
        @app = app
      end

      def call(env)
        Thread.current[:logged_request_env] = env

        request = ActionDispatch::Request.new(env)

        if loggers.length > 0
          loggers_tagged(loggers, request) { @app.call(env) }
        else
          @app.call(env)
        end
      ensure
        Thread.current[:logged_request_env] = nil
      end

      private

      def loggers
        @loggers ||= Logged.components.map { |c| Logged.logger_by_component(c) }.compact.uniq
      end

      def loggers_tagged(loggers, request, &block)
        logger = loggers.shift
        tags   = tags_for_component(logger.component, request)

        if loggers.length > 0
          tagged_block(logger, tags) { loggers_tagged(loggers, request, &block) }
        else
          tagged_block(logger, tags) { block.call }
        end
      end

      def tagged_block(logger, tags, &block)
        if logger.respond_to?(:tagged)
          logger.tagged(*tags, &block)
        else
          dummy_tagged(&block)
        end
      end

      def dummy_tagged
        yield
      end

      def tags_for_component(component, request)
        tags  = Logged.config.tags || []
        tags += Logged.config[component].tags || []

        compute_tags(tags, request)
      end

      def compute_tags(tags, request)
        tags.map do |tag|
          case tag
          when Proc
            tag.call(request)
          when Symbol
            request.send(tag)
          else
            tag
          end
        end
      end
    end
  end
end
