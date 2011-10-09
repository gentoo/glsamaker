class GlsaMailer < ActionMailer::Base
  default :from => GLSAMAKER_FROM_EMAIL,
            :content_type => 'text/plain'

  def new_request(recipient, glsa, requestor)
    @requestor = requestor
    @glsa = glsa

    mail(:to => recipient.email,
         :subject => "[GLSAMaker] New request: #{glsa.last_revision.title}")
  end

  def edit(recipient, glsa, diff, editor)
    @editor = editor
    @diff = diff
    @glsa = glsa

    mail(:to => recipient.email,
         :subject => "[GLSAMaker] Draft edit: #{glsa.last_revision.title}")
  end

  def comment(recipient, glsa, comment, commentator)
    @commentator = commentator
    @comment = comment
    @glsa = glsa

    mail(:to => recipient.email,
         :subject => "[GLSAMaker] Draft commented: #{glsa.last_revision.title}")
  end

  def approval(recipient, glsa)
    @glsa = glsa

    mail(:to => recipient.email,
         :subject => "[GLSAMaker] Draft approved: #{glsa.last_revision.title}")
  end

  def text(recipient, subject, text, footer)
    @text = text
    @footer = footer

    mail(:to => recipient.email,
         :subject => subject)
  end
end
