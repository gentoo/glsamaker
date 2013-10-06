ThinkingSphinx::Index.define :bug, :with => :active_record do
  indexes whiteboard

  has revision_id
end

ThinkingSphinx::Index.define :cve_comment, :with => :active_record do
  indexes comment
  has user_id, cve_id
end

ThinkingSphinx::Index.define :cve, :with => :active_record do
  indexes cve_id, :sortable => true
  indexes state,  :sortable => true
  indexes summary

  has published_at, last_changed_at
end

ThinkingSphinx::Index.define :glsa, :with => :active_record do
  indexes glsa_id, :sortable => true
end

ThinkingSphinx::Index.define :revision, :with => :active_record do
  indexes title
  indexes synopsis
  indexes description
  indexes impact
  indexes workaround
  indexes resolution
  indexes is_release

  has glsa_id, revid, release_revision
end