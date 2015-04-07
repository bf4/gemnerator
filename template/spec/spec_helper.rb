require 'bundler/setup'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
require 'pathname'
module AppRoot
  ROOT = Pathname File.expand_path('../..', __FILE__)
  def root
    ROOT
  end
  module_function :root
end
def app_root
  AppRoot.root
end
require_relative 'helper_config'
