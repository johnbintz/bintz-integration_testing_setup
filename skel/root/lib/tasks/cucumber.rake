# cuke-pack rake task
#
begin
  require 'cucumber/rake/task'

  namespace :cucumber do
    Cucumber::Rake::Task.new(:ok, 'Run all features') do |t|
      t.profile = 'default'
    end

    Cucumber::Rake::Task.new(:precommit, 'Only run features that should be tested before committing') do |t|
      t.profile = 'precommit'
    end

    Cucumber::Rake::Task.new(:wip, 'Only run features being worked on') do |t|
      t.profile = 'wip'
    end
  end

  task :cucumber => 'cucumber:precommit'
rescue LoadError
  $stderr.puts "no cucumber, skipping"
end

