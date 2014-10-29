require 'logged/formatter/base'

module Logged
  module Formatter
    # Raw formatter for logged
    class Raw < Base
      def call(data)
        data
      end
    end
  end
end
