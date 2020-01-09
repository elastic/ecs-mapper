require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

task :example do |t|
  system("./map --file example/mapping.csv")
  system("cp example/logstash.conf example/logstash/2-ecs-conversion.conf")
  system("cat example/beats/config_header.yml example/beats.yml > example/beats/filebeat.yml")
end
