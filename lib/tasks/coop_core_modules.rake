# Ops-level flag toggling with no deploy (design §12#5). Sets the
# installation (environment, tier 6) default for a module -- per-cooperative
# overrides go through the API (GET/PATCH /coop/modules).
namespace :coop_core do
  desc 'Enable a CoopFlow module at the installation scope. Usage: bundle exec rails "coop_core:enable_module[market]"'
  task :enable_module, [:module_key] => :environment do |_task, args|
    CoopCore::ModuleDefault.find_or_initialize_by(module_key: CoopCore::Feature::Registry.find(args[:module_key]).key)
                           .update!(enabled: true)
    puts "Enabled '#{args[:module_key]}' at installation scope."
  end

  desc 'Disable a CoopFlow module at the installation scope. Usage: bundle exec rails "coop_core:disable_module[market]"'
  task :disable_module, [:module_key] => :environment do |_task, args|
    CoopCore::ModuleDefault.find_or_initialize_by(module_key: CoopCore::Feature::Registry.find(args[:module_key]).key)
                           .update!(enabled: false)
    puts "Disabled '#{args[:module_key]}' at installation scope."
  end
end
