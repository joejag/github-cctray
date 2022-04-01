require "rubygems"
require "bundler/setup"

Bundler.require(:default)

task(:default)

# rubocop:disable Lint/SuppressedException
begin
  require "rspec/core/rake_task"

  desc("Run all specs in spec directory (excluding plugin specs)")
  RSpec::Core::RakeTask.new(:spec)

  Rake::Task["default"].enhance([:spec])
rescue LoadError
end

begin
  require "rubocop/rake_task"

  desc("Run rubocop")
  task(:rubocop) do
    RuboCop::RakeTask.new
  end

  Rake::Task["default"].enhance([:rubocop])
rescue LoadError
end
# rubocop:enable Lint/SuppressedException
