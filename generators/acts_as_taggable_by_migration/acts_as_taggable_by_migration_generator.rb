class ActsAsTaggableByMigrationGenerator < Rails::Generator::Base 
  def manifest 
    record do |m| 
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => "acts_as_taggable_by_migration"
    end
  end
end
