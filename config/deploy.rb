set :application, "glsamaker"
set :repository,  "git://git.overlays.gentoo.org/proj/glsamaker.git"

set :use_sudo, false

set :scm, :git

role :web, "lark.gentoo.org"                          # Your HTTP server, Apache/etc
role :app, "lark.gentoo.org"                          # This may be the same as your `Web` server
role :db,  "lark.gentoo.org", :primary => true # This is where Rails migrations will run

#set :user, 'TODO'
set :deploy_to, "/var/www/glsamaker2.gentoo.org"

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
end
