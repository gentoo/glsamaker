set :application, "glsamaker"
set :repository,  "git://git.overlays.gentoo.org/proj/glsamaker.git"

set :use_sudo, false

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, "stingray.a3li.li"                          # Your HTTP server, Apache/etc
role :app, "stingray.a3li.li"                          # This may be the same as your `Web` server
role :db,  "stingray.a3li.li", :primary => true # This is where Rails migrations will run

set :user, 'alex'
set :deploy_to, "/home/#{user}/trash/#{application}"

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

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
