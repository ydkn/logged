module Logged
  # Conversion between log level symbols and integers
  module LevelConversion
    def level_to_const(level)
      ::Logger.const_get(level.to_s.upcase)
    end

    def level_to_sym(level)
      case level
      when ::Logger::FATAL then :fatal
      when ::Logger::ERROR then :error
      when ::Logger::WARN  then :warn
      when ::Logger::INFO  then :info
      when ::Logger::DEBUG then :debug
      else                      :unknown
      end
    end
  end
end
