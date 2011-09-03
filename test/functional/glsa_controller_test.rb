require 'test_helper'

class GlsaControllerTest < ActionController::TestCase
  fixtures :glsas

  def setup
    @actions = [:show, :edit, :update, :diff, :prepare_release, :release, :import_references]
  end

  # Basic tests for the four permission groups
  test "should apply contributor permissions for restricted advisories correctly" do
    @actions.each do |action|
      log_in_as :contributor
      get action, :id => glsas(:restricted_glsa).id
      assert_access_denied "Failed action: #{action.to_s}"
    end
  end

  test "should apply padawan permissions for restricted advisories correctly" do
    @actions.each do |action|
      log_in_as :padawan
      get action, :id => glsas(:restricted_glsa).id
      assert_access_denied "Failed action: #{action.to_s}"
    end
  end

  test "should apply regular member permissions for restricted advisories correctly" do
    @actions.each do |action|
      log_in_as :full_member
      get action, :id => glsas(:restricted_glsa).id
      assert_access_denied "Failed action: #{action.to_s}"
    end
  end

  test "should apply confidential member permissions for restricted advisories correctly" do
    @actions.each do |action|
      next if action == :update # TODO
      next if action == :diff # TODO

      next if action == :prepare_release # Confidential drafts cannot be released
      next if action == :release         # ditto
      
      log_in_as :confidential_member
      get action, :id => glsas(:restricted_glsa).id
      assert_response :success, "Failed action: #{action.to_s}"
    end
  end

  # Specific tests for contributors
  test "should apply contributor permissions for their own drafts correctly" do
    @actions.each do |action|
      next if action == :update # TODO
      next if action == :diff # TODO

      next if action == :prepare_release # Off-limits for contributors
      next if action == :release         # ditto

      log_in_as :contributor
      get action, :id => glsas(:contributor_draft).id
      assert_response :success, "Failed action: #{action.to_s}"
    end
  end

  test "should apply contributor permissions for other drafts correctly" do
    @actions.each do |action|
      log_in_as :contributor
      get action, :id => glsas(:glsa_one).id
      assert_access_denied "Failed action #{action.to_s}"
    end
  end

  test "should not allow padawans to release advisories" do
    log_in_as :padawan
    get :prepare_release, :id => glsas(:glsa_one).id
    assert_access_denied "Prepare release test failed"

    log_in_as :padawan
    get :release, :id => glsas(:glsa_one).id
    assert_access_denied "Release tes failed"
  end

  # TODO: listing pages
end
