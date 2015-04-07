RSpec.configure do |config|
  config.include Module.new {
    def log(msg)
      RSpec.configuration.reporter.message "\n#{msg}\n"
    end

    def app_root
      @app_root ||=
        defined?(AppRoot) && AppRoot.root || Pathname(Dir.pwd)
    end
  }
end
