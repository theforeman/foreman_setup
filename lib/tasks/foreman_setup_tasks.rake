# Tasks
namespace :foreman_setup do
  namespace :example do
    desc 'Example Task'
    task task: :environment do
      # Task goes here
    end
  end
end

# Tests
namespace :test do
  desc 'Test ForemanSetup'
  Rake::TestTask.new(:foreman_setup) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
  end
end

namespace :foreman_setup do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_setup) do |task|
        task.patterns = ["#{ForemanSetup::Engine.root}/app/**/*.rb",
                         "#{ForemanSetup::Engine.root}/lib/**/*.rb",
                         "#{ForemanSetup::Engine.root}/test/**/*.rb"]
      end
    rescue
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_setup'].invoke
  end
end

Rake::Task[:test].enhance do
  Rake::Task['test:foreman_setup'].invoke
end

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task['jenkins:unit'].enhance do
    Rake::Task['test:foreman_setup'].invoke
    Rake::Task['foreman_setup:rubocop'].invoke
  end
end
