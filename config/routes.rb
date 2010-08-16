ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "index"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  
  # Bugzilla interface
  map.bug '/bug/:id', :controller => 'bug', :action => 'bug'
  map.bughistory '/bug/:id/history', :controller => 'bug', :action => 'history'

  # Adding a bug to a GLSA and removing a bug from a GLSA
  map.addbug '/glsa/:id/addbug', :controller => 'glsa', :action => 'addbug'
  map.addbugsave '/glsa/:id/addbug/save', :controller => 'glsa', :action => 'addbugsave'
  
  map.delbug '/glsa/:id/delbug/:bugid', :controller => 'glsa', :action => 'delbug'
 
  # Adding a comment to a GLSA
  map.addcomment '/glsa/:id/addcomment', :controller => 'glsa', :action => 'addcomment'
  map.addcommentsave '/glsa/:id/addcomment/save', :controller => 'glsa', :action => 'addcommentsave'
  
  map.requests '/glsa/requests', :controller => 'glsa', :action => 'requests'
  map.drafts   '/glsa/drafts'  , :controller => 'glsa', :action => 'drafts'
  map.sent     '/glsa/archive' , :controller => 'glsa', :action => 'archive'
  
  map.diff '/glsa/diff/:id/rev/:from/to/:to', :controller => 'glsa', :action => 'diff'
  
  map.newglsa '/glsa/new/:what', :controller => 'glsa', :action => 'new'
  
  map.showglsa '/glsa/show/:id.:format', :controller => 'glsa', :action => 'show'
  
  map.bugzie '/tools/bug/:id/:what', :controller => 'tools', :action => 'bugzie'
  
  
  map.cve '/cve/list.:format', :controller => 'cve', :action => 'list'
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
