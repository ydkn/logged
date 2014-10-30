require 'logged/formatter/base'
require 'logged/formatter/key_value'

module Logged
  module Formatter
    # Logstash formatter for logged
    class Logstash < Base
      def initialize(message_formatter = nil)
        @message_formatter = message_formatter || KeyValue.new
      end

      def call(data)
        load_dependencies

        event = LogStash::Event.new(data)
        event[:message] = @message_formatter.call(data)

        event.to_json
      end

      private

      def load_dependencies
        require 'logstash-event'
      rescue LoadError
        STDERR.puts 'You need to install the logstash-event gem to use the logstash formatter.'
        raise
      end
    end
  end
end
