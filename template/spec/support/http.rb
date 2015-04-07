begin
  require 'webmock/rspec'
  # Uncomment to allow connections on localhost
  # WebMock.disable_net_connect!(allow_localhost: true)
rescue LoadError
end
begin
  require 'vcr'
  # https://github.com/vcr/vcr/blob/master/lib/vcr/test_frameworks/rspec.rb
  VCR.configure do |config|
    config.cassette_library_dir = app_root.join('spec/fixtures/vcr_cassettes')
    config.hook_into :webmock
    # default_cassette_options: {
    #  match_requests_on: [:method, :uri],
    #  record: :once
    # }
  end
  # for more vcr options see
  # http://www.relishapp.com/vcr/vcr/v/2-9-3/docs/hooks
  # https://relishapp.com/vcr/vcr/v/2-9-3/docs/cassettes
  # https://relishapp.com/vcr/vcr/v/2-9-3/docs/configuration
  # http://www.relishapp.com/vcr/vcr/v/2-9-3/docs/cassettes/cassette-persistence
  #
  # Some useful options:
  #  http://www.relishapp.com/vcr/vcr/v/2-9-3/docs/record-modes
  #  record: :once / :none / :new_episodes /: all
  #
  #  re_record_interval: 10000 # in seconds. Uses record mode :all when expired
  #
  #  http://www.relishapp.com/vcr/vcr/v/2-9-3/docs/request-matching/playback-repeats
  #  allow_playback_repeats: true
  #
  #  http://www.relishapp.com/vcr/vcr/v/2-9-3/docs/request-matching
  #  match_requests_on: [:host]
  #
  #  port_matcher = lambda do |request_1, request_2|
  #    URI(request_1.uri).port == URI(request_2.uri).port
  #  end
  #  match_requests_on: [:method, port_matcher]
  #  http://www.relishapp.com/vcr/vcr/v/2-9-3/docs/request-matching/register-and-use-a-custom-matcher
  #  config.register_request_matcher :port do |request_1, request_2|
  #    URI(request_1.uri).port == URI(request_2.uri).port
  #  end
  #  match_requests_on: [:method, :port]
  #
  #  match_requests_on: [:body_as_json]
  #
  #  match_requests_on: [:method,
  #      VCR.request_matchers.uri_without_param(:timestamp)]
  #  match_requests_on: [:method,
  #      VCR.request_matchers.uri_without_params(:timestamp, :session)]
  #
  #  preserve_exact_body_bytes: true
  #
  #  prevent sensitive data from being written to your cassette file
  #  filter_sensitive_data: '<LOCATION>', :my_tag) { 'World' } # filter tag is optional
  #  USER_PASSWORDS = {'john.doe' => 'monkey', 'jane.doe' => 'cheetah' }
  #  filter_sensitive_data('<PASSWORD>') do |interaction|      # using block argument
  #    USER_PASSWORDS[interaction.request.headers['X-Http-Username'].first]
  #  end
  #
  #  ignore_request { |req| ... } # will ignore any request for which the given block returns true.
  #  ignore_hosts 'foo.com', 'bar.com' # allows you to specify particular hosts to ignore
  #  ignore_localhost = true # is equivalent to ignore_hosts 'localhost', '127.0.0.1', '0.0.0.0'.
  #    It is particularly useful for when you use VCR with a javascript-enabled capybara driver,
  #    since capybara boots your rack app and makes localhost requests to it to check that it has booted.
  #
  #  allow_unused_http_interactions: false # fails a passing test if a recorded interaction isn't used
  #
  #  http://www.relishapp.com/vcr/vcr/v/2-9-3/docs/cassettes/exclusive-cassette
  #  VCR allows cassettes to be nested.
  #  exclusive: true If you do not want the HTTP interactions of the outer cassette considered,
  #
  #  http://www.relishapp.com/vcr/vcr/v/2-9-3/docs/cassettes/dynamic-erb-cassettes
  #  erb: true/false
  #
  # http://www.relishapp.com/vcr/vcr/v/2-9-3/docs/cassettes/cassette-format
  #  serialize_with: :yaml, :json, :custom
  #
  # update_content_length_header: true # useful if you manually edit a cassette
  #
  # https://github.com/vcr/vcr/blob/master/lib/vcr/test_frameworks/rspec.rb
  require 'timecop'
  module VCRHelpers
    def with_cassette(cassette_name, options: {}, &block)
      VCR.use_cassette(cassette_name, options) do |cassette|
        Timecop.freeze(cassette.originally_recorded_at || Time.now) do
          block.call(Time.now)
        end
      end
    end
  end
  # Usage:
  # tag an example group or example with type: :web
  # Then, in an example
  # response = with_cassette("descriptive_name) do |time|
  #   # do something with the time
  #   Api.make_request
  # end
  RSpec.configuration.include VCRHelpers, type: :web
  when_tagged_with_api = { api: ->(v) { !!v } }
  RSpec.configuration.include VCRHelpers, when_tagged_with_api
rescue LoadError
end
