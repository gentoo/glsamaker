xml.instruct!
xml.instruct! :'xml-stylesheet', :href => '/xsl/glsa.xsl', :type => 'text/xsl'
xml.instruct! :'xml-stylesheet', :href => '/xsl/guide.xsl', :type => 'text/xsl'
xml.declare! :DOCTYPE, :glsa, :SYSTEM, "http://www.gentoo.org/dtd/glsa-2.dtd"

xml.glsa :id => glsa.glsa_id do
  xml.title glsa.last_revision.title
  xml.synopsis glsa.last_revision.synopsis
  xml.product :type => "ebuild" do
    xml.comment! "packages go here"
  end
  xml.announced "today"
  xml.revised "never"
  
  glsa.last_revision.bugs.each do |bug|
    xml.bug bug.bug_id
  end
  
  xml.access glsa.last_revision.access
  
  xml.affected do
    xml.comment! "packages go here"
  end
  
  xml.background(glsa.last_revision.background || "")
  
  xml.description do
    xml << (glsa.last_revision.description + "\n" || "")
  end
  
  xml.impact({:type => glsa.last_revision.severity}, glsa.last_revision.impact || "")
  
  xml.workaround(glsa.last_revision.workaround || "")
  
  xml.resolution do
    xml << (glsa.last_revision.resolution || "")
  end
  
  xml.references do
    glsa.last_revision.references.each do |ref|
      xml.uri({:link => ref.url}, ref.title)
    end
  end
  
  xml.metadata({:tag => 'requester', :timestamp => glsa.created_at.rfc2822}, glsa.requester.login)
  
  if glsa.submitter
    xml.metadata({:tag => 'submitter', :timestamp => glsa.last_revision.created_at.rfc2822}, glsa.submitter.login)
  end
  
  if glsa.bugreadymaker
    xml.metadata({:tag => 'bugReady', :timestamp => Time.now.rfc2822}, glsa.bugreadymaker.login)
  end
end
