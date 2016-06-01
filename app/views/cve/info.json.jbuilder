json.extract! @cve, :id, :cve_id, :summary, :cvss, :state, :published_at

json.references @cve.references, :source, :title, :uri

json.bugs @cve.assignments.map { |a| a.bug  }
