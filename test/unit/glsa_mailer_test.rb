require 'test_helper'

class GlsaMailerTest < ActionMailer::TestCase
  test "request" do
    @expected.subject = 'GlsaMailer#request'
    @expected.body    = read_fixture('request')
    @expected.date    = Time.now

    assert_equal @expected.encoded, GlsaMailer.create_request(@expected.date).encoded
  end

  test "edit" do
    @expected.subject = 'GlsaMailer#edit'
    @expected.body    = read_fixture('edit')
    @expected.date    = Time.now

    assert_equal @expected.encoded, GlsaMailer.create_edit(@expected.date).encoded
  end

  test "comment" do
    @expected.subject = 'GlsaMailer#comment'
    @expected.body    = read_fixture('comment')
    @expected.date    = Time.now

    assert_equal @expected.encoded, GlsaMailer.create_comment(@expected.date).encoded
  end

  test "approval" do
    @expected.subject = 'GlsaMailer#approval'
    @expected.body    = read_fixture('approval')
    @expected.date    = Time.now

    assert_equal @expected.encoded, GlsaMailer.create_approval(@expected.date).encoded
  end

  test "sent" do
    @expected.subject = 'GlsaMailer#sent'
    @expected.body    = read_fixture('sent')
    @expected.date    = Time.now

    assert_equal @expected.encoded, GlsaMailer.create_sent(@expected.date).encoded
  end

end
