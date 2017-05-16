# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170418102638) do

  create_table "bugs", force: :cascade do |t|
    t.integer  "bug_id",      limit: 4
    t.text     "title",       limit: 65535
    t.integer  "revision_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "whiteboard",  limit: 255
    t.string   "arches",      limit: 255
  end

  add_index "bugs", ["bug_id"], name: "index_bugs_on_bug_id", using: :btree
  add_index "bugs", ["revision_id"], name: "index_bugs_on_revision_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "glsa_id",    limit: 4
    t.text     "text",       limit: 65535
    t.string   "rating",     limit: 255
    t.boolean  "read",       limit: 1,     default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["glsa_id"], name: "index_comments_on_glsa_id", using: :btree
  add_index "comments", ["user_id"], name: "comments_users_userid", using: :btree

  create_table "cpes", force: :cascade do |t|
    t.string   "cpe",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cpes", ["cpe"], name: "index_cpes_on_cpe", unique: true, using: :btree

  create_table "cpes_cves", id: false, force: :cascade do |t|
    t.integer  "cpe_id",     limit: 4
    t.integer  "cve_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cpes_cves", ["cpe_id"], name: "cpes_cves_cpe_id", using: :btree
  add_index "cpes_cves", ["cve_id", "cpe_id"], name: "index_cpes_cves_on_cve_id_and_cpe_id", using: :btree

  create_table "cve_assignments", force: :cascade do |t|
    t.integer  "cve_id",     limit: 4
    t.integer  "bug",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cve_assignments", ["bug"], name: "index_cve_assignments_on_bug", using: :btree
  add_index "cve_assignments", ["cve_id"], name: "index_cve_assignments_on_cve_id", using: :btree

  create_table "cve_changes", force: :cascade do |t|
    t.integer  "cve_id",     limit: 4
    t.integer  "user_id",    limit: 4
    t.string   "action",     limit: 255
    t.string   "object",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cve_changes", ["cve_id"], name: "cve_changes_cve_id", using: :btree
  add_index "cve_changes", ["user_id"], name: "cve_changes_user_id", using: :btree

  create_table "cve_comments", force: :cascade do |t|
    t.integer  "cve_id",       limit: 4
    t.integer  "user_id",      limit: 4
    t.boolean  "confidential", limit: 1,     default: false
    t.text     "comment",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cve_comments", ["cve_id"], name: "index_cve_comments_on_cve_id", using: :btree
  add_index "cve_comments", ["user_id"], name: "cve_comments_user_id", using: :btree

  create_table "cve_references", force: :cascade do |t|
    t.string   "source",     limit: 255
    t.text     "title",      limit: 65535
    t.text     "uri",        limit: 65535
    t.integer  "cve_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cve_references", ["cve_id"], name: "index_cve_references_on_cve_id", using: :btree

  create_table "cves", force: :cascade do |t|
    t.string   "cve_id",          limit: 255
    t.text     "summary",         limit: 65535
    t.string   "cvss",            limit: 255
    t.string   "state",           limit: 255
    t.datetime "published_at"
    t.datetime "last_changed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cves", ["cve_id"], name: "index_cves_on_cve_id", unique: true, using: :btree

  create_table "glsas", force: :cascade do |t|
    t.string   "glsa_id",           limit: 255
    t.integer  "requester",         limit: 4
    t.integer  "submitter",         limit: 4
    t.integer  "bugreadymaker",     limit: 4
    t.string   "status",            limit: 255
    t.boolean  "restricted",        limit: 1,   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "first_released_at"
  end

  add_index "glsas", ["bugreadymaker"], name: "glsas_users_bugreadymakers", using: :btree
  add_index "glsas", ["glsa_id"], name: "index_glsas_on_glsa_id", unique: true, using: :btree
  add_index "glsas", ["requester"], name: "glsas_users_requesters", using: :btree
  add_index "glsas", ["status"], name: "index_glsas_on_status", using: :btree
  add_index "glsas", ["submitter"], name: "glsas_users_submitters", using: :btree

  create_table "packages", force: :cascade do |t|
    t.integer  "revision_id", limit: 4
    t.string   "my_type",     limit: 255
    t.string   "atom",        limit: 255
    t.string   "version",     limit: 255
    t.string   "comp",        limit: 255
    t.string   "arch",        limit: 255
    t.boolean  "automatic",   limit: 1,   default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slot",        limit: 255
  end

  add_index "packages", ["atom"], name: "atom", using: :btree
  add_index "packages", ["comp"], name: "comp", using: :btree
  add_index "packages", ["revision_id"], name: "index_packages_on_revision_id", using: :btree
  add_index "packages", ["slot"], name: "slot", using: :btree

  create_table "references", force: :cascade do |t|
    t.integer  "revision_id", limit: 4
    t.text     "title",       limit: 65535
    t.text     "url",         limit: 65535
    t.string   "type",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "references", ["revision_id"], name: "index_references_on_revision_id", using: :btree

  create_table "revisions", force: :cascade do |t|
    t.integer  "glsa_id",          limit: 4
    t.integer  "revid",            limit: 4
    t.string   "title",            limit: 255
    t.string   "access",           limit: 255,   default: "remote"
    t.string   "product",          limit: 255
    t.string   "category",         limit: 255
    t.string   "severity",         limit: 255,   default: "normal"
    t.text     "synopsis",         limit: 65535
    t.text     "background",       limit: 65535
    t.text     "description",      limit: 65535
    t.text     "impact",           limit: 65535
    t.text     "workaround",       limit: 65535
    t.text     "resolution",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",          limit: 4
    t.boolean  "is_release",       limit: 1,     default: false
    t.integer  "release_revision", limit: 4
  end

  add_index "revisions", ["glsa_id"], name: "index_revisions_on_glsa_id", using: :btree
  add_index "revisions", ["revid"], name: "index_revisions_on_revid", using: :btree
  add_index "revisions", ["title"], name: "index_revisions_on_title", using: :btree
  add_index "revisions", ["user_id"], name: "revisions_user_userid", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "templates", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.text     "text",       limit: 65535
    t.string   "target",     limit: 255
    t.boolean  "enabled",    limit: 1,     default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "login",       limit: 255
    t.string   "name",        limit: 255
    t.string   "email",       limit: 255
    t.boolean  "disabled",    limit: 1,     default: false
    t.boolean  "jefe",        limit: 1,     default: false
    t.text     "preferences", limit: 65535
    t.integer  "access",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["login"], name: "index_users_on_login", unique: true, using: :btree

  add_foreign_key "comments", "glsas", name: "comments_glsas_glsaid"
  add_foreign_key "comments", "users", name: "comments_users_userid"
  add_foreign_key "cpes_cves", "cpes", name: "cpes_cves_cpe_id"
  add_foreign_key "cpes_cves", "cves", name: "cpes_cves_cve_id"
  add_foreign_key "cve_assignments", "cves", name: "cve_assignments_cve_id"
  add_foreign_key "cve_changes", "cves", name: "cve_changes_cve_id"
  add_foreign_key "cve_changes", "users", name: "cve_changes_user_id"
  add_foreign_key "cve_comments", "cves", name: "cve_comments_cve_id"
  add_foreign_key "cve_comments", "users", name: "cve_comments_user_id"
  add_foreign_key "cve_references", "cves", name: "cve_references_cve_id"
  add_foreign_key "glsas", "users", column: "bugreadymaker", name: "glsas_users_bugreadymakers"
  add_foreign_key "glsas", "users", column: "requester", name: "glsas_users_requesters"
  add_foreign_key "glsas", "users", column: "submitter", name: "glsas_users_submitters"
  add_foreign_key "references", "revisions", name: "references_revisions_revisionid"
  add_foreign_key "revisions", "users", name: "revisions_user_userid"
end
