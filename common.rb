# see http://technology.stitchfix.com/blog/2014/01/06/rails-app-templates/
# http://guides.rubyonrails.org/rails_application_templates.html
# http://www.rubydoc.info/github/erikhuda/thor/master/Thor/Actions
# See http://railsdiff.org/ for what comes with rails new
#     https://github.com/rails-api/rails-api/blob/master/lib/rails-api/templates/rails/app/Gemfile
# modify source_path to include the files in our template dir

require 'fileutils'
@ruby_version = ENV.fetch('RBENV_VERSION') { '2.1.5' }
@safe_update = ENV.fetch('SAFE_UPDATE') { false } == 'true'
@overwrite_conflicts = ENV.fetch('OVERWRITE_CONFLICTS') { false } == 'true'
@skip_conflicts =
  case
  when @overwrite_conflicts then false
  when @safe_update         then true
  else ENV['SKIP_CONFLICTS'] == 'true'
  end

# A little introspection to what this is:
#
# p self.class
# Rails::Generators::AppGenerator
# https://github.com/rails/rails/blob/4-2-stable/railties/lib/rails/generators/rails/app/app_generator.rb
# https://github.com/rails/rails/blob/4-2-stable/railties/lib/rails/generators/app_base.rb#L11
# https://github.com/rails/rails/blob/4-2-stable/railties/lib/rails/generators/base.rb#L15
# https://github.com/erikhuda/thor/blob/v0.19.1/lib/thor/group.rb#L7
#
# p self.inspect
# "#<Rails::Generators::AppGenerator:0x007fac41b4c680
# @gem_filter=#<Proc:0x007fac41b4c518 gems/ruby-2.1.5/gems/railties-4.2.0/lib/rails/generators/app_base.rb:82 (lambda)>,
# @extra_entries=[],
# @behavior=:invoke,
# @_invocations={},
# @_initializer=[[#<Pathname:~/projects/casebook>], {}, {:destination_root=>#<Pathname:~/projects/casebook>}],
# @options={\"ruby\"=>\"~/.rvm/rubies/ruby-2.1.5/bin/ruby\", \"skip_gemfile\"=>false, \"skip_bundle\"=>false, \"skip_git\"=>false, \"skip_keeps\"=>false, \"skip_active_record\"=>false, \"skip_sprockets\"=>false, \"skip_spring\"=>false, \"database\"=>\"sqlite3\", \"javascript\"=>\"jquery\", \"skip_javascript\"=>false, \"dev\"=>false, \"edge\"=>false, \"skip_turbolinks\"=>false, \"skip_test_unit\"=>false, \"rc\"=>false, \"no_rc\"=>false},
# @app_path=#<Pathname:~/projects/casebook>,
# @args=[],
# @shell=#<Thor::Shell::Color:0x007fac41a57748
# @base=#<Rails::Generators::AppGenerator:0x007fac41b4c680 ...>,
# @mute=false,
# @padding=0,
# @always_force=false>,
# @destination_stack=[\"~/projects/casebook\"],
# @in_group=nil,
# @after_bundle_callbacks=[],
# @source_paths=[\"~/.rvm/gems/ruby-2.1.5/bundler/gems/rails-api-6a80a367cd0f/lib/rails-api/templates/rails/app\", \"~/.rvm/gems/ruby-2.1.5/gems/railties-4.2.0/lib/rails/generators/rails/app/templates\"],
# @ruby_version=\"2.1.5\",
# @rails_version=\"~> 4.2.0\",
# @app_name=\"Casebook\",
# @safe_update=true>"
#
# p @options
# {"ruby"=>"~/.rvm/rubies/ruby-2.1.5/bin/ruby",
# "skip_gemfile"=>false,
# "skip_bundle"=>false,
# "skip_git"=>false,
# "skip_keeps"=>false,
# "skip_active_record"=>false,
# "skip_sprockets"=>false,
# "skip_spring"=>false,
# "database"=>"sqlite3",
# "javascript"=>"jquery",
# "skip_javascript"=>false,
# "dev"=>false,
# "edge"=>false,
# "skip_turbolinks"=>false,
# "skip_test_unit"=>false,
# "rc"=>false,
# "no_rc"=>false}
if @overwrite_conflicts
  puts "Setting conflict resolution default to 'force'"
  @options = @options.dup.merge('force' => true)
elsif @skip_conflicts
  puts "Setting conflict resolution default to 'skip'"
  @options = @options.dup.merge('skip' => true)
end

@template_dirname = ENV.fetch('TEMPLATE_DIRNAME')

def source_paths
  [File.join(File.expand_path(File.dirname(__FILE__)), @template_dirname)] +
    Array(super)
end
# https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/string/strip.rb#L22
def strip_heredoc(string)
  indent = string.scan(/^[ \t]*(?=\S)/).min.size
  string.gsub(/^[ \t]{#{indent}}/, '')
end

def bundle_command(command)
  # We are going to shell out rather than invoking Bundler::CLI.new(command)
  # because `rails new` loads the Thor gem and on the other hand bundler uses
  # its own vendored Thor, which could be a different version. Running both
  # things in the same process is a recipe for a night with paracetamol.
  #
  # We use backticks and #print here instead of vanilla #system because it
  # is easier to silence stdout in the existing test suite this way. The
  # end-user gets the bundler commands called anyway, so no big deal.
  #
  # We unset temporary bundler variables to load proper bundler and Gemfile.
  #
  # Thanks to James Tucker for the Gem tricks involved in this call.
  _bundle_command = Gem.bin_path('bundler', 'bundle')

  require 'bundler'
  Bundler.with_clean_env do
    output = `"#{Gem.ruby}" "#{_bundle_command}" #{command}`
    print output unless options[:quiet]
  end
end
