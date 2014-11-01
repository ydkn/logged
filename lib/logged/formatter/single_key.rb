require 'logged/formatter/base'

module Logged
  module Formatter
    # Single-Key formatter for logged
    class SingleKey < Base
      def initialize(key)
        @key = key
      end

      def call(data)
        data[@key]
      end
    end
  end
end
