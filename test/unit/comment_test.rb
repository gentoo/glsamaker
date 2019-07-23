require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  fixtures :all

  test "padawans should not be able to make approvals" do
    c = Comment.new
    c.glsa_id = 1
    c.user = users(:test_padawan)
    c.text = "test"
    c.rating = "approval"
    c.save

    assert c.errors.any?
    assert_includes c.errors[:rating], "You may not approve or reject drafts"
  end

  test "padawans should not be able to make rejections" do
    c = Comment.new
    c.glsa_id = 1
    c.user = users(:test_padawan)
    c.text = "test"
    c.rating = "rejection"
    c.save

    assert c.errors.any?
    assert_includes c.errors[:rating], "You may not approve or reject drafts"
  end

  test "advisory owners should not be able to approve their own drafts" do
    c = Comment.new
    c.user_id = 1
    c.text = "test"
    c.rating = "approval"
    c.glsa_id = 2
    c.save
    
    assert c.errors.any?
    assert_equal ["The owner of a draft cannot make approvals or rejections"], c.errors[:rating]
  end

  test "users should not be able to approve a draft twice" do
    # second comment loaded from fixtures
    c = Comment.new
    c.user_id = 7
    c.text = "test"
    c.rating = "approval"
    c.glsa_id = 2
    c.save

    assert c.errors.any?
    assert_equal ["You have already approved or rejected this draft"], c.errors[:rating]
  end
end
