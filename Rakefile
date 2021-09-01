require "rubygems"
require "bundler/setup"
require "rspec/core/rake_task"
require "rubocop/rake_task"

Bundler.require(:default)

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)

desc "Run rubocop"
task :rubocop do
  RuboCop::RakeTask.new
end

task default: %i[spec rubocop]

