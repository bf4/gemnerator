require 'simplecov' # see .simplecov for run options

require 'pathname'
@spec_root = Pathname File.expand_path('..', __FILE__)

# Requires supporting Ruby files with custom matchers and macros, etc,
#
require @spec_root.join('quality_spec')
# in spec/support/ and its subdirectories.
Dir[@spec_root.join('support/**/*.rb')].each { |f| require f }
# Requires shared specs
Dir[@spec_root.join('shared/**/*.rb')].each { |f| require f }
# in spec/support/ and its subdirectories.
Dir[app_root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  # Skip specs tagged `:slow` unless SLOW_SPECS is set
  config.filter_run_excluding :slow unless ENV['SLOW_SPECS']
  # End specs on first failure if FAIL_FAST is set
  config.fail_fast = ENV.include?('FAIL_FAST')
  config.order = :rand
  config.color = true
  config.disable_monkey_patching!
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  # :suite after/before all specs
  # :each every describe block
  # :all every it block
end
