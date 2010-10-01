xml.instruct!
xml.instruct! :'xml-stylesheet', :href => '/xsl/glsa.xsl', :type => 'text/xsl'
xml.instruct! :'xml-stylesheet', :href => '/xsl/guide.xsl', :type => 'text/xsl'
xml.declare! :DOCTYPE, :glsa, :SYSTEM, "http://www.gentoo.org/dtd/glsa-2.dtd"

xml.glsa :id => glsa.glsa_id do
  xml.title rev.title
  xml.synopsis rev.synopsis
  xml.product :type => "ebuild" do
    xml.comment! "packages go here"
  end
  xml.announced "today"
  xml.revised "never"
  
  rev.bugs.each do |bug|
    xml.bug bug.bug_id
  end
  
  xml.access rev.access
  
  xml.affected do
    xml.comment! "packages go here"
  end
  
  xml.background(rev.background || "")
  
  xml.description do
    xml << (rev.description || "") + "\n"
  end
  
  xml.impact({:type => rev.severity}, rev.impact || "")
  
  xml.workaround(rev.workaround || "")
  
  xml.resolution do
    xml << (rev.resolution || "")
  end
  
  xml.references do
    rev.references.each do |ref|
      xml.uri({:link => ref.url}, ref.title)
    end
  end
  
  xml.metadata({:tag => 'requester', :timestamp => glsa.created_at.rfc2822}, glsa.requester.login)
  
  if glsa.submitter
    xml.metadata({:tag => 'submitter', :timestamp => rev.created_at.rfc2822}, glsa.submitter.login)
  end
  
  if glsa.bugreadymaker
    xml.metadata({:tag => 'bugReady', :timestamp => Time.now.rfc2822}, glsa.bugreadymaker.login)
  end
end
