# Usage:
# ruby gemnerator.rb NAME
# https://github.com/erikhuda/thor/wiki/Generators
# http://blog.tamouse.org/swaac/2014/03/08/playing-around-with-thor-generators/
# Inheriting from Thor::Group causes the defined methods to be executed in order
# rather than subcommands, when inheriting from 'Thor'
# e.g. https://github.com/bundler/bundler/blob/91633430cb/lib/bundler/cli.rb#L339-L352
#      https://github.com/bundler/bundler/blob/91633430cb/lib/bundler/cli/gem.rb#L18-L103
#      https://github.com/bundler/bundler/blog/91633430cb/lib/bundler/templates/newgem/Gemfile.tt
# class Bundler::CLI < Thor
#   class Gem
#     def initialize(options, gem_name, thor)
#      def run
#        opts = { :name => name, etc.
#        templates = { "Gemfile.tt" => "Gemfile", etc
#        templates.each do |src, dst|
#          thor.template("newgem/#{src}", target.join(dst), opts)
#        end
#   def gem(name)
#      Gem.new(options, name, self).run
#   end
#   def self.source_root
#     File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
#   end
require 'bundler'
require 'thor'
require 'thor/group'
require 'pathname'
class Gemnerator < Thor::Group
  include Thor::Actions
  add_runtime_options!
  class_option :verbose, default: false

  # expect one argument upon invocation,
  argument :name
  attr_reader :template_file

  def initialize(args = [], options = {}, config = {})
    @template_file = config.fetch(:template_file)
    super
    self.destination_root = File.join(config[:projects_root], name)
  end

  desc <<-FOO
Description:
  This generator makes or updates gems from a template
  FOO

  def self.source_root
    File.expand_path('../template', __FILE__)
  end

  def app_name
    @app_name ||= snake_name
  end

  def target_dir
    Pathname(destination_root).join(name)
  end

  # see https://github.com/bundler/bundler/blob/13f44d1241ca7a7ce435bd43790a26a0a140126b/lib/bundler/cli/gem.rb#L21-L43
  def bundler_config
    @config ||=
      begin
        underscored_name = name.tr('-', '_')
        namespaced_path = name.tr('-', '/')
        constant_name = name.gsub(/-[_-]*(?![_-]|$)/) { '::' }.gsub(/([_-]+|(::)|^)(.|$)/) { Regexp.last_match(2).to_s + Regexp.last_match(3).upcase }

        constant_array = constant_name.split('::')
        git_user_name = `git config user.name`.chomp
        git_user_email = `git config user.email`.chomp

        config = {
          name: name,
          underscored_name: underscored_name,
          namespaced_path: namespaced_path,
          makefile_path: "#{underscored_name}/#{underscored_name}",
          constant_name: constant_name,
          constant_array: constant_array,
          author: git_user_name.empty? ? 'TODO: Write your name' : git_user_name,
          email: git_user_email.empty? ? 'TODO: Write your email address' : git_user_email,
          test: options[:test],
          ext: options[:ext],
          bin: options[:bin],
          bundler_version: '1',
          verbose: options[:verbose]
        }
        if name =~ /^\d/
          STDERR.puts "Invalid gem name #{name} Please give a name which does not start with numbers."
          exit 1
        elsif Object.const_defined?(constant_array.first)
          STDERR.puts "Invalid gem name #{name} constant #{constant_array.join('::')} is already in use. Please choose another gem name."
          exit 1
        end
        config
      end
  end

  # see https://github.com/bundler/bundler/blob/13f44d1241ca7a7ce435bd43790a26a0a140126b/lib/bundler/cli/gem.rb#L107-L109
  def apply_bundler_template
    bundler_templates.each do |src, dst|
      template(src, target_dir.join(dst), bundler_config)
    end
  end

  def target_dir
    Pathname(destination_root)
  end

  # see https://github.com/bundler/bundler/tree/13f44d1241ca7a7ce435bd43790a26a0a140126b/lib/bundler/templates/newgem
  def bundler_template_dir
    # File.join(Gem.loaded_specs["bundler"].full_gem_path, "lib/bundler/templates/new_gem")
    # Bundler templates files not findable in source paths directly
    # so vendoring here :(
    File.expand_path("../bundler_template", __FILE__)
  end

  # see https://github.com/bundler/bundler/blob/13f44d1241ca7a7ce435bd43790a26a0a140126b/lib/bundler/cli/gem.rb#L45-L105
  def bundler_templates
    namespaced_path = bundler_config.fetch(:namespaced_path)
    templates = {
      'lib/newgem.rb.tt' => "lib/#{namespaced_path}.rb",
      'lib/newgem/version.rb.tt' => "lib/#{namespaced_path}/version.rb",
      'newgem.gemspec.tt' => "#{name}.gemspec",
      'bin/console.tt' => 'bin/console',
    }
    templates.merge!('CODE_OF_CONDUCT.md.tt' => 'CODE_OF_CONDUCT.md')
    templates.merge!('LICENSE.txt.tt' => 'LICENSE.txt')
    templates.merge!(
      'rspec.tt' => '.rspec',
      'spec/newgem_spec.rb.tt' => "spec/#{namespaced_path}_spec.rb"
    )
  end

  def source_paths
    [bundler_template_dir] +
      Array(super)
  end

  def apply_template
    apply(template_file, verbose: options[:verbose])
  end

  private

  # munging on potential input from the user
  # 'Able & Louis: Go @@CRAXY@@' becomes
  # ["Able", "Louis", "Go", "CRAXY"]
  def name_components
    @_name_components ||= name.scan(/[[:alnum:]]+/)
  end

  # ["Able", "Louis", "Go", "CRAXY"] become
  # able_louis_go_craxy
  def snake_name
    @_snake_name ||= name_components.map(&:downcase).join('_')
  end
end
projects_root = ENV.fetch('PROJECT_DIR')
template = ENV.fetch('LOCATION')
fail 'No template LOCATION value given. Please set LOCATION either as path to a file or a URL' if template.nil?
fail "Template #{template} does not exist" unless File.readable?(template)
template = File.expand_path(template) if template !~ %r{\A[A-Za-z][A-Za-z0-9+\-\.]*://}
args = ARGV
config = {
  projects_root: projects_root,
  template_file: template
}
Gemnerator.start(args, config)
