# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090314194257) do

  create_table "glsas", :force => true do |t|
    t.string   "glsa_id"
    t.integer  "requester"
    t.integer  "submitter"
    t.integer  "bugreadymaker"
    t.string   "status"
    t.integer  "last_revision_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "glsas", ["bugreadymaker"], :name => "glsas_users_bugreadymakers"
  add_index "glsas", ["glsa_id"], :name => "index_glsas_on_glsa_id", :unique => true
  add_index "glsas", ["requester"], :name => "glsas_users_requesters"
  add_index "glsas", ["status"], :name => "index_glsas_on_status"
  add_index "glsas", ["submitter"], :name => "glsas_users_submitters"

  create_table "permissions", :force => true do |t|
    t.string   "name"
    t.string   "title"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["name"], :name => "index_permissions_on_name", :unique => true

  create_table "permissions_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "permission_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions_users", ["permission_id"], :name => "permissions_users_permissions"
  add_index "permissions_users", ["user_id", "permission_id"], :name => "index_permissions_users_on_user_id_and_permission_id"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "name"
    t.string   "email"
    t.boolean  "disabled",    :default => false
    t.text     "preferences"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
