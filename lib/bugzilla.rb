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

# Bugzilla module
module Bugzilla
  # Encapsulates a Bugzilla Bug
  class Bug
    attr_reader :summary, :created_at, :reporter, :alias, :assigned_to, :cc, :status_whiteboard,
                :product, :component, :status, :resolution, :url, :comments, :bug_id
    
    # Creates a new +Bug+ object from the Gentoo bug referenced as #+bugid+
    def self.load_from_id(bugid)
      begin
        id = Integer(bugid)
        
        raise ArgumentError if id == 0
      rescue ArgumentError => e
        raise ArgumentError, "Invalid Bug ID"
      end
      
      begin
        xml = Nokogiri::XML(Glsamaker::HTTP.get("http://bugs.gentoo.org/show_bug.cgi?ctype=xml&id=#{id}"))
      rescue Exception => e
        raise ArgumentError, "Couldn't load bug: #{e.message}"
      end
      
      self.new(xml.root.xpath("bug").first)
    end

    # Returns the URL for the bug, set +secure+ to false to get a http:-URL
    def url(secure = true)
      if secure
        "https://bugs.gentoo.org/show_bug.cgi?id=#{@bug_id}"
      else
        "http://bugs.gentoo.org/show_bug.cgi?id=#{@bug_id}"
      end
    end
    
    def history()
      @history ||= History.new(self)
    end
    
    def initialize(bug)
      unless bug.is_a? Nokogiri::XML::Element
        raise ArgumentError, "Nokogiri failure"
      end
      
      if bug["error"] == "NotFound"
        raise ArgumentError, "Bug not found"
      end
      
      @bug_id = xml_content(bug, 'bug_id')
      @summary = xml_content(bug, 'short_desc')
      @created_at = Time.parse(xml_content(bug, 'creation_ts'))
      @reporter = xml_content(bug, 'reporter')
      @alias = xml_content(bug, 'alias')
      @assigned_to = xml_content(bug, 'assigned_to')
      @cc = xml_content(bug, 'cc')
      @status_whiteboard = xml_content(bug, 'status_whiteboard')
      @product = xml_content(bug, 'product')
      @component = xml_content(bug, 'component')
      @status = xml_content(bug, 'bug_status')
      @resolution = xml_content(bug, 'resolution')
      @url = xml_content(bug, 'bug_file_loc')
      
      @comments = []
      bug.xpath('long_desc').each do |comment|
        @comments << Comment.new(
          xml_content(comment, 'who'), 
          xml_content(comment, 'thetext'),
          xml_content(comment, 'bug_when')
        )
      end
    end
    
    # Splits a String +str+ into an array of valid bug IDs
    def self.str2bugIDs(str)
      bug_ids = str.split(/,\s*/)

      bug_ids.map do |bug|
        bug.gsub(/\D/, '')
      end
    end
    
    private
    def xml_content(bug, xpath) 
      if bug.xpath(xpath).first
        bug.xpath(xpath).first.content
      else
        ""
      end
    end
  end
  
  # Encapsulates a comment to a Bug
  class Comment
    attr_reader :author, :text, :date
    
    def initialize(by, text, date)
      @author = by
      @text = text
      @date = Time.parse(date)
    end
  end
  
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
  
  # Encapsulates a bug's history
  class History
    attr_reader :changes
    
    # Creates a new History for the Bug object +bug+.
    def initialize(bug)
      unless bug.respond_to? :bug_id
        raise ArgumentError, "Need a bug (or something that at least looks like a bug)"
      end
      
      begin
        html = Nokogiri::HTML(Glsamaker::HTTP.get("http://bugs.gentoo.org/show_activity.cgi?id=#{bug.bug_id}"))
      rescue Exception => e
        raise ArgumentError, "Couldn't load the bug history: #{e.message}"
      end
      
      @changes = []
      change_cache = nil
      
      html.xpath("/html/body/table/tr").each do |change|
        # ignore header line
        next if change.children.first.name == "th"
    
        # First line in a multi-change set
        unless (chcount = change.children.first["rowspan"]) == nil
          change_cache = Change.new(change.children.first.content.strip, change.children[2].content.strip)
          
          change_cache.add_change(
            change.children[4].content.strip.downcase.to_sym,
            change.children[6].content.strip,
            change.children[8].content.strip
          )
          
          @changes << change_cache          
        else
          change_cache.add_change(
            change.children[0].content.strip.downcase.to_sym,
            change.children[2].content.strip,
            change.children[4].content.strip
          )
        end
      end
    end
    
    # Returns an Array of Changes made to the field +field+
    def by_field(field)
      raise(ArgumentError, "Symbol expected") unless field.is_a? Symbol
      
      changes = []
      
      @changes.each do |change|
        if change.changes.has_key?(field)
          changes << change
        end
      end
    
      changes
    end
    
    # Returns an Array of Changes made by the user +user+
    def by_user(user)
      changes = []
      
      @changes.each do |change|
        if change.user == user
          changes << change
        end
      end
      
      changes
    end
  end
  
  # This represents a single Change made to a Bug
  class Change
    attr_reader :user, :time, :changes
    
    # Creates a new Change made by +user+ at +time+.
    def initialize(user, time)
      @user = user || ""
      @time = Time.parse(time)
      @changes = {}
    end
    
    # Adds a changed +field+ to the Change object. +removed+ denotes the removed text
    # and +added+ is the new text
    def add_change(field, removed, added)    
      raise(ArgumentError, "A change to this field is already registered.") if @changes.has_key?(field)
      raise(ArgumentError, "field has to be a symbol") unless field.is_a? Symbol
      
      @changes[field] = [removed, added]
    end

    # Returns a string representation
    def to_s
      "#{@user} changed at #{@time.to_s}: #{@changes.inspect}"
    end
  end
  
end