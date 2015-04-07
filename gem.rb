ENV['TEMPLATE_DIRNAME'] ||= 'template'
dir = File.expand_path("..", __FILE__)
eval File.read(File.join(dir, "common.rb")), binding, __FILE__, __LINE__

@bundle_commands = []
def after_bundle(&block)
  @bundle_commands << block
end

def run_bundle_commands
  bundle_command 'check || bundle'
  @bundle_commands.each(&:call)
end

template 'README.md.erb', 'README.md' unless @safe_update

# Gems
# ==================================================
remove_file 'Gemfile' unless @safe_update
template 'Gemfile.erb', 'Gemfile' unless @safe_update
copy_file 'Gemfile.shared'
template '.ruby-version.erb', '.ruby-version'

# Rakefile
# ==================================================
remove_file 'Rakefile'
copy_file 'Rakefile'

# Ignore rails doc files, Vim/Emacs swap files, .DS_Store, and more
# ===================================================
remove_file '.gitignore'
copy_file '.gitignore_template', '.gitignore'

# Guard
# ==================================================
copy_file 'Guardfile'
after_bundle do
  bundle_command 'binstub guard'
end

# RSpec
# ==================================================
copy_file '.rspec'
inside 'spec' do
  %w(spec_helper.rb helper_config.rb capture_warnings.rb quality_spec.rb).each do |file|
    remove_file file unless @safe_update
    copy_file file
  end
  inside 'support' do
    %w(factory_girl.rb http.rb support.rb timeout.rb).each do |file|
      remove_file file unless @safe_update
      copy_file file
    end
  end
end

after_bundle do
  bundle_command 'binstub rspec-core'
end

# Rubocop
# ==================================================
copy_file '.rubocop.yml'
copy_file '.rubocop_todo.yml' unless @safe_update
after_bundle do
  bundle_command 'binstub rubocop'
end

# Yard
# ==================================================
after_bundle do
  bundle_command 'binstub yard'
end

# Pry
# ==================================================
copy_file '.pryrc'

# SimpleCov
# ==================================================
copy_file '.simplecov'

# Other
# ==================================================
inside 'reports' do
  copy_file '.keep'
end

inside 'tasks' do
  copy_file 'notes.rake'
  copy_file 'rspec.rake'
  copy_file 'yard.rake'
  copy_file 'rubocop.rake'
end

# Dotenv
# ==================================================
template '.env.erb', '.env'
empty_directory 'env'
inside 'env' do
  copy_file '.keep'
end


# pass through FIRST_TIME from the env
# skip all git hooks
ENV['SKIP'] = 'all'
Dir.chdir(target_dir) do
  # Make sure there's git
  run "[ -d .git ] || $(git init; git add .; git commit -m 'Initial commit')"
  inside 'bin' do
    %w(setup).each do |cmd|
      remove_file cmd
      copy_file cmd
      run "chmod a+x #{cmd}"
    end
  end
  chmod "bin", 0755 & ~File.umask, verbose: false
  run_bundle_commands
  bundle_command 'config --local console pry'
  bundle_command 'exec bin/setup' unless @safe_update || @overwrite_conflicts
  # bundle_command 'exec rubocop --auto-correct'
end
