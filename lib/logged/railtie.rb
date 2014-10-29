require 'rails/railtie'
require 'logged/configuration'

module Logged
  # Railtie for logged
  class Railtie < Rails::Railtie
    config.logged = Configuration.new

    initializer :logged do |app|
      Logged.setup(app) if app.config.logged.enabled
    end
  end
end
