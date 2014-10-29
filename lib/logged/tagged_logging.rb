module Logged
  # Tagged logging support
  module TaggedLogging
    def tagged(*tags)
      new_tags = push_tags(*tags)

      yield self
    ensure
      pop_tags(new_tags.size)
    end

    def flush
      current_tags.clear
    end

    def push_tags(*tags)
      tags.flatten.reject(&:blank?).tap do |new_tags|
        current_tags.concat(new_tags)
      end
    end

    def pop_tags(size = 1)
      current_tags.pop(size)
    end

    def current_tags
      Thread.current["logged_logger_tags_#{component}"] ||= []
    end
  end
end
