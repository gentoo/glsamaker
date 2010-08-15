# ===GLSAMaker v2
#  Copyright (C) 2009 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

require 'nokogiri'
require 'fastercsv'
require 'fileutils'

module Bugzilla ; end

%w[ comment bug history ].each {|lib| require File.join(File.dirname(__FILE__), "bugzilla/#{lib}")}

# Bugzilla module
module Bugzilla
  # Looks on bugs.gentoo.org for all bugs that are in the [glsa] state
  module_function
  def find_glsa_bugs
    url="http://bugs.gentoo.org/buglist.cgi?bug_file_loc=&bug_file_loc_type=allwordssubstr&bug_id=&bug_status=UNCONFIRMED&bug_status=NEW&bug_status=ASSIGNED&bug_status=REOPENED&bugidtype=include&chfieldfrom=&chfieldto=Now&chfieldvalue=&component=Vulnerabilities&email1=&email2=&emailassigned_to1=1&emailassigned_to2=1&emailcc2=1&emailreporter2=1&emailtype1=substring&emailtype2=substring&field-1-0-0=product&field-1-1-0=component&field-1-2-0=bug_status&field-1-3-0=status_whiteboard&field0-0-0=noop&keywords=&keywords_type=allwords&long_desc=&long_desc_type=substring&product=Gentoo%20Security&query_format=advanced&remaction=&short_desc=&short_desc_type=allwordssubstr&status_whiteboard=%5Bglsa%5D&status_whiteboard_type=substring&type-1-0-0=anyexact&type-1-1-0=anyexact&type-1-2-0=anyexact&type-1-3-0=substring&type0-0-0=noop&value-1-0-0=Gentoo%20Security&value-1-1-0=Vulnerabilities&value-1-2-0=UNCONFIRMED%2CNEW%2CASSIGNED%2CREOPENED&value-1-3-0=%5Bglsa%5D&value0-0-0=&votes=&ctype=csv"
    bugs = []
    
    FasterCSV.parse(Glsamaker::HTTP.get(url)) do |row|
      bugs << { "bug_id" => row.shift,
                "severity" => row.shift,
                "priority" => row.shift,
                "os" => row.shift,
                "assignee" => row.shift,
                "status" => row.shift,
                "resolution" => row.shift,
                "summary" => row.shift
              }
    end
    
    bugs.shift
    bugs
  end
  
  def add_comment(bug, comment)
    Float(bug)
    cookie_file = File.join(RAILS_ROOT, 'tmp', 'bugzie-cookies.yaml')
    
    a = Mechanize.new { |agent|
      agent.user_agent = "GLSAMaker/#{GLSAMAKER_VERSION} (http://security.gentoo.org/)"
    }

    a.cookie_jar.load(cookie_file)
    
    a.get("https://bugs.gentoo.org/show_bug.cgi?id=%s" % bug) do |page|
      unless page.body.include? '*+*GLSAMAKER-LOGGEDIN*+*'
        log_in()
        a.cookie_jar.load(cookie_file)
      end
      
      post_result = page.form_with(:name => 'changeform') do |form|
        form.comment = comment
      end.submit

      raise unless post_result.body.include? "Changes submitted for bug"
    end
  end
  
  def log_in
    raise unless GLSAMAKER_BUGZIE_USER and GLSAMAKER_BUGZIE_PW
      a = Mechanize.new { |agent|
        agent.user_agent = "GLSAMaker/#{GLSAMAKER_VERSION} (http://security.gentoo.org/)"
      }

      a.get("https://bugs.gentoo.org/index.cgi?GoAheadAndLogIn=1") do |page|
        login_result = page.form_with(:name => 'login') do |form|
          form['Bugzilla_login'] = GLSAMAKER_BUGZIE_USER
          form['Bugzilla_password'] = GLSAMAKER_BUGZIE_PW
        end.submit

        if login_result.body.include? '*+*GLSAMAKER-LOGGEDIN*+*'
          cookie_file = File.join(RAILS_ROOT, 'tmp', 'bugzie-cookies.yaml')
          FileUtils.touch(cookie_file)
          File.chmod(0600, cookie_file)
          a.cookie_jar.save_as(cookie_file)
        end
      end
    
  end
end