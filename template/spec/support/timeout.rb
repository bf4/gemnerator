require 'timeout'
# No spec should run longer than this
#   (define here to support the closure)
if ENV['NO_TIMEOUT'] !~ /true|1/i
  puts "setting timeout #{timeout = 15.0} seconds"
  RSpec.configuration.around(:each) do |example|
    Timeout.timeout(timeout, &example)
  end
end
