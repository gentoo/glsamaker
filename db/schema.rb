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

ActiveRecord::Schema.define(:version => 20100814142647) do

  create_table "bugs", :force => true do |t|
    t.integer  "bug_id"
    t.text     "title"
    t.integer  "revision_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "whiteboard"
    t.string   "arches"
  end

  add_index "bugs", ["revision_id"], :name => "index_bugs_on_revision_id"

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "glsa_id"
    t.text     "text"
    t.string   "rating"
    t.boolean  "read",       :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["glsa_id"], :name => "index_comments_on_glsa_id"
  add_index "comments", ["user_id"], :name => "comments_users_userid"

  create_table "cpes", :force => true do |t|
    t.string   "cpe"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cpes", ["cpe"], :name => "index_cpes_on_cpe", :unique => true

  create_table "cpes_cves", :id => false, :force => true do |t|
    t.integer  "cpe_id"
    t.integer  "cve_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cpes_cves", ["cpe_id"], :name => "cpes_cves_cpe_id"
  add_index "cpes_cves", ["cve_id", "cpe_id"], :name => "index_cpes_cves_on_cve_id_and_cpe_id"

  create_table "cve_changes", :force => true do |t|
    t.integer  "cve_id"
    t.integer  "user_id"
    t.string   "action"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cve_changes", ["cve_id"], :name => "cve_changes_cve_id"
  add_index "cve_changes", ["user_id"], :name => "cve_changes_user_id"

  create_table "cve_comments", :force => true do |t|
    t.integer  "cve_id"
    t.integer  "user_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cve_comments", ["cve_id"], :name => "index_cve_comments_on_cve_id"
  add_index "cve_comments", ["user_id"], :name => "cve_comments_user_id"

  create_table "cve_references", :force => true do |t|
    t.string   "source"
    t.string   "title"
    t.string   "uri"
    t.integer  "cve_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cve_references", ["cve_id"], :name => "index_cve_references_on_cve_id"

  create_table "cves", :force => true do |t|
    t.string   "cve_id"
    t.text     "summary"
    t.string   "cvss"
    t.string   "state"
    t.datetime "published_at"
    t.datetime "last_changed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cves", ["cve_id"], :name => "index_cves_on_cve_id", :unique => true

  create_table "glsas", :force => true do |t|
    t.string   "glsa_id"
    t.integer  "requester"
    t.integer  "submitter"
    t.integer  "bugreadymaker"
    t.string   "status"
    t.boolean  "restricted",    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "glsas", ["bugreadymaker"], :name => "glsas_users_bugreadymakers"
  add_index "glsas", ["glsa_id"], :name => "index_glsas_on_glsa_id", :unique => true
  add_index "glsas", ["requester"], :name => "glsas_users_requesters"
  add_index "glsas", ["status"], :name => "index_glsas_on_status"
  add_index "glsas", ["submitter"], :name => "glsas_users_submitters"

  create_table "packages", :force => true do |t|
    t.integer  "revision_id"
    t.string   "my_type"
    t.string   "atom"
    t.string   "version"
    t.string   "comp"
    t.string   "arch"
    t.boolean  "automatic",   :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "packages", ["revision_id"], :name => "index_packages_on_revision_id"

  create_table "references", :force => true do |t|
    t.integer  "revision_id"
    t.text     "title"
    t.text     "url"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "references", ["revision_id"], :name => "index_references_on_revision_id"

  create_table "revisions", :force => true do |t|
    t.integer  "glsa_id"
    t.integer  "revid"
    t.string   "title"
    t.string   "access",      :default => "remote"
    t.string   "product"
    t.string   "category"
    t.string   "severity",    :default => "normal"
    t.text     "synopsis"
    t.text     "background"
    t.text     "description"
    t.text     "impact"
    t.text     "workaround"
    t.text     "resolution"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "revisions", ["glsa_id"], :name => "index_revisions_on_glsa_id"
  add_index "revisions", ["revid"], :name => "index_revisions_on_revid"
  add_index "revisions", ["title"], :name => "index_revisions_on_title"
  add_index "revisions", ["user_id"], :name => "revisions_user_userid"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "name"
    t.string   "email"
    t.boolean  "disabled",    :default => false
    t.text     "preferences"
    t.integer  "access"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
