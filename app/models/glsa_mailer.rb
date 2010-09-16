class GlsaMailer < ActionMailer::Base

  def request(sent_at = Time.now)
    subject    'GlsaMailer#request'
    recipients ''
    from       ''
    sent_on    sent_at
    
    body       :greeting => 'Hi,'
  end

  def edit(user, glsa, revision, edit_user)
    subject    "[GLSAMaker] Draft edit: '#{revision.title}'"
    recipients user.email
    from       GLSAMAKER_FROM_EMAIL
    sent_on    Time.now

    body       :glsa => glsa, :revision => revision, :user => edit_user
  end

  def comment(sent_at = Time.now)
    subject    'GlsaMailer#comment'
    recipients ''
    from       ''
    sent_on    sent_at
    
    body       :greeting => 'Hi,'
  end

  def approval(sent_at = Time.now)
    subject    'GlsaMailer#approval'
    recipients ''
    from       ''
    sent_on    sent_at
    
    body       :greeting => 'Hi,'
  end

  def sent(sent_at = Time.now)
    subject    'GlsaMailer#sent'
    recipients ''
    from       ''
    sent_on    sent_at
    
    body       :greeting => 'Hi,'
  end

end
