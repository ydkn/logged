require 'spec_helper'
require 'logged'
require 'rails'

RSpec.describe 'Logged Configuration' do
  before do
    class Application < Rails::Application
      config.eager_load = true

      config.logged.enabled = true
    end

    Rails.application.initialize!
  end

  it 'enables logged' do
    expect(Logged.config.enabled).to eq(true)
  end
end
