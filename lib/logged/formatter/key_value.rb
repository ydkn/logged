require 'logged/formatter/base'

module Logged
  module Formatter
    # Key-Value formatter for logged
    class KeyValue < Base
      def call(data)
        data
          .reject { |_k, v| v.nil? || (v.is_a?(String) && v.blank?) }
          .map { |k, v| format_key(k, v) }
          .join(' ')
      end

      def format_key(key, value)
        # encapsulate in singe quote if value is a string
        value = "'#{value}'" if value.is_a?(String)

        # ensure only two decimals
        value = Kernel.format('%.2f', value) if value.is_a?(Float)

        "#{key}=#{value}"
      end
    end
  end
end
