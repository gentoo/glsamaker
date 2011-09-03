require 'test_helper'

class RevisionTest < ActiveSupport::TestCase
  test "deep copy" do
    revision = revisions(:revision_one)
    new_revision = revision.deep_copy
    
    assert_equal(revision.title, new_revision.title)
    assert_equal(revision.glsa_id, new_revision.glsa_id)
    assert_equal(revision.access, new_revision.access)
    assert_equal(revision.product, new_revision.product)
    assert_equal(revision.category, new_revision.category)
    assert_equal(revision.severity, new_revision.severity)
    assert_equal(revision.synopsis, new_revision.synopsis)
    assert_equal(revision.background, new_revision.background)
    assert_equal(revision.description, new_revision.description)
    assert_equal(revision.impact, new_revision.impact)
    assert_equal(revision.workaround, new_revision.workaround)
    assert_equal(revision.resolution, new_revision.resolution)
    
    # Assuming that if the bug ID is copied, so is the rest
    assert_equal(revision.bugs.map{|bug| bug.bug_id}.sort, new_revision.bugs.map{|bug| bug.bug_id}.sort)
    
    assert_equal(revision.references.map{|ref| ref.url}.sort, new_revision.references.map{|ref| ref.url}.sort)
    assert_equal(
      revision.packages.map{|pkg| "#{pkg.comp}#{pkg.atom}-#{pkg.version}"}.sort,
      new_revision.packages.map{|pkg| "#{pkg.comp}#{pkg.atom}-#{pkg.version}"}.sort
    )
  end
  
  test "linked bugs" do
    assert_equal([236060, 260006], revisions(:revision_one).get_linked_bugs.sort)
  end

  test "malformed XML" do
    revision = revisions(:revision_one)
    revision.description = "<h1>hi"

    revision.save
    assert revision.errors.any?
    assert_equal [:description, "is not well-formed XML"], revision.errors.first

    revision.description = "hi"
    revision.save
    assert_equal false, revision.errors.any?
  end
end
