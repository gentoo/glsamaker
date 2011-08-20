# ===GLSAMaker v2
#  Copyright (C) 2010 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

# Encapsulates a Bugzilla Bug
module Bugzilla
  class Bug
    attr_reader :summary, :created_at, :reporter, :alias, :assigned_to, :cc, :status_whiteboard,
                :product, :component, :status, :resolution, :url, :comments, :bug_id, :restricted,
                :severity, :priority, :depends, :blocks

    alias :title :summary

    # Creates a new +Bug+ object from the Gentoo bug referenced as #+bugid+
    def self.load_from_id(bugid)
      begin
        id = Integer(bugid)

        raise ArgumentError if id == 0
      rescue ArgumentError => e
        raise ArgumentError, "Invalid Bug ID"
      end

      begin
        xml = Nokogiri::XML(Glsamaker::HTTP.get("https://#{GLSAMAKER_BUGZIE_HOST}/show_bug.cgi?ctype=xml&id=#{id}"))
      rescue SocketError => e
        raise SocketError, "Bugzilla is unreachable: #{e.message}"
      rescue Exception => e
        raise ArgumentError, "Couldn't load bug: #{e.message}"
      end

      self.new(xml.root.xpath("bug").first, bugid)
    end

    # Returns the URL for the bug, set +secure+ to false to get a http:-URL
    def url(secure = true)
      if secure
        "https://#{GLSAMAKER_BUGZIE_HOST}/show_bug.cgi?id=#{@bug_id}"
      else
        "http://#{GLSAMAKER_BUGZIE_HOST}/show_bug.cgi?id=#{@bug_id}"
      end
    end

    def history()
      @history ||= History.new(self)
    end

    def initialize(bug, id)
      unless bug.is_a? Nokogiri::XML::Element
        raise ArgumentError, "Nokogiri failure"
      end

      if bug["error"] == "NotFound"
        raise ArgumentError, "Bug not found"
      elsif bug["error"] == "NotPermitted"
        @bug_id = id
        @restricted = true
        return
      end

      @restricted = false
      @cc = []
      @depends = []
      @blocks = []
      @comments = []

      bug.children.each do |node|
        # Ignore whitespace
        next if node.type == Nokogiri::XML::Node::TEXT_NODE
        # Ignore empty nodes
        next if node.children.size == 0

        case node.name
        when "bug_id" then
          @bug_id = content_in node
        when "short_desc" then
          @summary = content_in node
        when "creation_ts" then
          @created_at = Time.parse(content_in(node))
        when "reporter" then
          @reporter = content_in node
        when "alias" then
          @alias = content_in node
        when "assigned_to" then
          @assigned_to = content_in node
        when "cc" then
          @cc << content_in(node)
        when "status_whiteboard" then
          @status_whiteboard = content_in node
        when "product" then
          @product = content_in node
        when "component" then
          @component = content_in node
        when "bug_status" then
          @status = content_in node
        when "resolution" then
          @resolution = content_in node
        when "bug_file_loc" then
          @url = content_in node
        when "bug_severity" then
          @severity = content_in node
        when "priority" then
          @priority = content_in node
        when "dependson" then
          @depends << content_in(node)
        when "blocked" then
          @blocks << content_in(node)
        when "long_desc" then
          @comments << Bugzilla::Comment.new(
            node.xpath("who").first.children.first.to_s,
            node.xpath("thetext").first.children.first.to_s,
            node.xpath("bug_when").first.children.first.to_s
          )
        end
      end
    end

    # Returns the initial bug description
    def description
      @comments.first.text
    end

    # Splits a String +str+ into an array of valid bug IDs
    def self.str2bugIDs(str)
      bug_ids = str.split(/,\s*/)

      bug_ids.map do |bug|
        bug.gsub(/\D/, '')
      end
    end

    private
    def content_in(node)
      node.children.first.content.strip
    end
  end
end
