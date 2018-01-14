xml.instruct!
xml.declare! :DOCTYPE, :glsa, :SYSTEM, "http://www.gentoo.org/dtd/glsa.dtd"

xml.glsa :id => glsa.glsa_id do
  xml.title rev.title
  xml.synopsis rev.synopsis
  xml.product({:type => "ebuild"}, rev.product)
  xml.announced glsa.release_date.strftime '%Y-%m-%d'
  xml.revised({:count => "#{rev.release_revision || 'draft'}"}, glsa.revised_date.strftime('%Y-%m-%d'))

  rev.bugs.each do |bug|
    xml.bug bug.bug_id
  end

  xml.access rev.release_access
  logger.debug rev.packages_by_atom.inspect
  xml.affected do
    rev.packages_by_atom.each_pair do |package, atoms|
      xml.package({:name => package, :auto => (atoms['unaffected'] || []).select {|a| !a.automatic}.length == 0 ? 'yes' : 'no',
              :arch => (atoms['vulnerable'].nil? || atoms['vulnerable'].length == 0) ? '*' : atoms['vulnerable'].first.arch}) do
        (atoms['unaffected'] || []).each do |a|
	  if a.slot != '*'
            xml.unaffected({:range => a.xml_comp, :slot => a.slot}, a.version)
          else
	    xml.unaffected({:range => a.xml_comp}, a.version)
	  end
        end
        (atoms['vulnerable'] || []).each do |a|
	  if a.slot != '*'
            xml.vulnerable({:range => a.xml_comp, :slot => a.slot}, a.version)
	  else
	    xml.vulnerable({:range => a.xml_comp}, a.version)
	  end
        end
      end
    end
  end

  xml.background do
    xml << xml_format(rev.background || "")
  end

  xml.description do
    xml << xml_format(rev.description || "")
  end

  xml.impact({:type => rev.severity}) do
    xml << xml_format(rev.impact || "")
  end

  xml.workaround do
    xml << xml_format(rev.workaround || "")
  end

  xml.resolution do
    xml << xml_format(rev.resolution || "")
  end

  xml.references do
    rev.references.each do |ref|
      xml.uri({:link => ref.url}, ref.title)
    end
  end

  xml.metadata({:tag => 'requester', :timestamp => glsa.created_at.iso8601}, glsa.requester.login)

  if glsa.submitter
    xml.metadata({:tag => 'submitter', :timestamp => rev.created_at.iso8601}, glsa.submitter.login)
  end

  if glsa.bugreadymaker
    xml.metadata({:tag => 'bugReady', :timestamp => Time.now.iso8601}, glsa.bugreadymaker.login)
  end
end
