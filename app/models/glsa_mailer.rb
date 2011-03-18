class GlsaMailer < ActionMailer::Base

  def request(user, glsa, edit_user)
    subject    "[GLSAMaker] New request: '#{glsa.last_revision.title}'"    
    recipients user.email
    from       GLSAMAKER_FROM_EMAIL
    sent_on    Time.now
    
    body       :glsa => glsa, :user => edit_user
  end

  def edit(user, glsa, diff, edit_user)
    subject    "[GLSAMaker] Draft edit: '#{glsa.last_revision.title}'"
    recipients user.email
    from       GLSAMAKER_FROM_EMAIL
    sent_on    Time.now

    body       :glsa => glsa, :diff => diff, :user => edit_user
  end

  def comment(user, glsa, comment, edit_user)
    subject    "[GLSAMaker] Draft commented: '#{glsa.last_revision.title}'"
    recipients user.email
    from       GLSAMAKER_FROM_EMAIL
    sent_on    Time.now
    
    body       :glsa => glsa, :comment => comment, :user => edit_user
  end

  def approval(user, glsa)
    subject    "[GLSAMaker] Draft approved: '#{glsa.last_revision.title}'"
    recipients user.email
    from       GLSAMAKER_FROM_EMAIL
    sent_on    Time.now

    body       :glsa => glsa
  end

  def sent(sent_at = Time.now)
    subject    'GlsaMailer#sent'
    recipients ''
    from       ''
    sent_on    sent_at
    
    body       :greeting => 'Hi,'
  end

  def text(user, _subject, text, footer)
    subject    _subject
    recipients user.email
    from       GLSAMAKER_FROM_EMAIL
    sent_on    Time.now

    body       :text => text, :footer => footer
  end

end
