# frozen_string_literal: true

RSpec.configure do |config|
  config.color_mode = :off if ENV['CI']

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Before and after filters for the rspec runner

  if ENV['CI']
    config.before(:example, :focus) do
      raise 'This example was committed with `:focus` and should not have been'
    end
  end
end
