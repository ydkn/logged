require 'json'
require 'logged/formatter/base'

module Logged
  module Formatter
    # JSON formatter for logged
    class JSON < Base
      def call(data)
        ::JSON.dump(data)
      end
    end
  end
end
