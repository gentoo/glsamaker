xml.instruct!
xml.instruct! :'xml-stylesheet', :href => '/xsl/glsa.xsl', :type => 'text/xsl'
xml.instruct! :'xml-stylesheet', :href => '/xsl/guide.xsl', :type => 'text/xsl'
xml.declare! :DOCTYPE, :glsa, :SYSTEM, "http://www.gentoo.org/dtd/glsa-2.dtd"

xml.glsa :id => glsa.glsa_id do
  xml.title rev.title
  xml.synopsis rev.synopsis
  xml.product({:type => "ebuild"}, rev.product)
  xml.announced rev.created_at.strftime '%B %d, %Y'
  xml.revised rev.created_at.strftime('%B %d, %Y') + ": #{rev.release_revision || 'draft'}"
  
  rev.bugs.each do |bug|
    xml.bug bug.bug_id
  end
  
  xml.access rev.access
  logger.debug rev.packages_by_atom.inspect
  xml.affected do
    rev.packages_by_atom.each_pair do |package, atoms|
      xml.package({:name => package, :auto => (atoms['unaffected'] || []).select {|a| !a.automatic}.length == 0 ? 'yes' : 'no',
              :arch => atoms['vulnerable'].first.arch}) do
        (atoms['unaffected'] || []).each do |a|
          xml.unaffected({:range => a.xml_comp}, a.version)
        end
        (atoms['vulnerable'] || []).each do |a|
          xml.vulnerable({:range => a.xml_comp}, a.version)
        end
      end
    end
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
