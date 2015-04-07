if ENV['FULL_BUILD'] != 'true' # skip on Travis
  require 'rubocop'
  require 'rubocop/rake_task'

  Rake::Task[:rubocop].clear if Rake::Task.task_defined?(:rubocop)
  desc 'Run RuboCop'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.patterns = [
      'lib/**/*.rb',
      'config/**/*.rb',
      'spec/**/*.rb',
      'app/**/*.rb',
      'bin/*'
    ]
    # only show the files with failures
    task.formatters = ['files']
    # don"t abort rake on failure
    task.fail_on_error = false
  end
end
