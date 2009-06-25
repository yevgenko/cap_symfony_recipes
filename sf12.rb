namespace (:sf12) do
  desc <<-DESC
    Run the "symfony cc" task
  DESC
  task :cc do
    run "cd #{latest_release} && #{php} symfony cc"
  end
  desc <<-DESC
    Remove DEV environments
  DESC
  task :cleanup do
    run "rm -rf #{latest_release}/web/*_dev.php"
  end
  desc <<-DESC
    Disable symfony application
  DESC
  task :disable do
    run "cd #{current_path} && #{php} symfony disable #{sf_app} prod"
  end
  desc <<-DESC
    Enable symfony application
  DESC
  task :enable do
    run "cd #{current_path} && #{php} symfony enable #{sf_app} prod"
  end
  desc <<-DESC
    Create symlink to symfony specific targets
  DESC
  task :symlinks do
    # symlink to database.yml
    run "rm -rf #{latest_release}/config/databases.yml"
    run "ln -s #{shared_path}/databases.yml #{latest_release}/config/databases.yml"

    # symlink to sf data dir
    run "rm -rf #{latest_release}/web/sf"
    run "ln -s #{latest_release}/lib/vendor/symfony/data/web/sf #{latest_release}/web/sf"

    # symlink plugins
    run "cd #{latest_release} && rm -rf web/*Plugin"
    run "cd #{latest_release} && #{php} symfony plugin:publish-asset"

    # symlink to uploads
    run "mkdir -p #{shared_path}/uploads/assets"
    run "rm -rf #{latest_release}/web/uploads"
    run "ln -s #{shared_path}/uploads #{latest_release}/web/uploads"

    # symlink to .htaccess
    run "rm -rf #{latest_release}/web/.htaccess"
    run "ln -s #{shared_path}/.htaccess #{latest_release}/web/.htaccess"
  end

  namespace (:propel) do
    desc <<-DESC
      configure database
    DESC
    task :configure do
      set :dbname, Capistrano::CLI.ui.ask('Database: ')
      set :dbusername, Capistrano::CLI.ui.ask('DB User: ')
      set :dbpassword, Capistrano::CLI.password_prompt('DB Password: ')
      upload "config/databases.yml.tmp", "#{shared_path}/databases.yml.tmp", :via => :scp
      run "cat #{shared_path}/databases.yml.tmp | sed 's|@dbname@|#{dbname}|g' | sed 's|@username@|#{dbusername}|g' | sed 's|@password@|#{dbpassword}|g' > #{shared_path}/databases.yml"
    end

    desc <<-DESC
    Run the "propel:build-model", "propel:build-forms" and "propel:build-filters" tasks
    DESC
    task :build do
    run "cd #{latest_release} && #{php} symfony propel:build-model && #{php} symfony propel:build-forms && #{php} symfony propel:build-filters"
    end

    namespace (:migrate) do
      desc <<-DESC
      Run the "propel:migrate" task
      DESC
      task :migrate do
      run "cd #{latest_release} && #{php} symfony propel:migrate #{sf_app}"
      end
      desc <<-DESC
        Restart migration task
      DESC
      task :restart do
        run "cd #{current_path} && #{php} symfony propel:migrate #{sf_app} --revision=0"
        sf12.propel.migrate.migrate
      end
    end
  end
end
