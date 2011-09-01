require 'thinking_sphinx/deploy/capistrano'
require 'bundler/capistrano'

set :application, "glsamaker"
set :repository,  "git://git.overlays.gentoo.org/proj/glsamaker.git"

set :use_sudo, false

set :scm, :git

role :web, "pitaya.gentoo-ev.org"
role :app, "pitaya.gentoo-ev.org"
role :db,  "pitaya.gentoo-ev.org", :primary => true

set :user, 'glsamaker'
set :deploy_to, "/var/www/glsamaker"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :init do
    top.upload("config/deploy.private.rb", "#{deploy_to}/current/tmp/deploy.private.rb", {:mode => '0600'})
    run "cd #{deploy_to}/current/ && ./script/config_init"
  end

  desc "precompile the assets"
  task :precompile_assets, :roles => :web, :except => { :no_release => true } do
    run "cd #{current_path}; rm -rf public/assets/*"
    run "cd #{current_path}; RAILS_ENV=production bundle exec rake assets:precompile"
  end

  after "deploy:symlink", "deploy:init", "deploy:precompile_assets"
end
