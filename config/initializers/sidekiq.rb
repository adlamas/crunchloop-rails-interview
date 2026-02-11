Sidekiq.configure_server do |config|
  # Load the schedule configuration
  schedule_file = "config/sidekiq.yml"

  if File.exist?(schedule_file)
    schedule_hash = YAML.load_file(schedule_file)[:scheduler][:schedule]
    Sidekiq::Cron::Job.load_from_hash(schedule_hash)
  end
end

