require 'nokogiri'
require 'open-uri'

module Bugzilla
  class Bug
    attr_reader :summary, :created_at, :reporter, :alias, :assigned_to, :cc, :status_whiteboard,
                :product, :component, :status, :resolution, :url, :comments, :bug_id
    
    def self.load_from_id(bugid)
      begin
        id = Integer(bugid)
      rescue ArgumentError => e
        raise ArgumentError, "Invalid Bug ID"
      end
      
      begin
        xml = Nokogiri::XML(open("http://bugs.gentoo.org/show_bug.cgi?ctype=xml&id=#{id}"))
      rescue Exception => e
        raise ArgumentError, "Couldn't load bug: #{e.message}"
      end
      
      self.new(xml.root.xpath("bug").first)
    end
    
    def url(secure = true)
      if secure
        "https://bugs.gentoo.org/show_bug.cgi?id=#{@bug_id}"
      else
        "http://bugs.gentoo.org/show_bug.cgi?id=#{@bug_id}"
      end
    end
    
    private
    def initialize(bug)
      unless bug.is_a? Nokogiri::XML::Element
        raise ArgumentError, "Nokogiri failure"
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
    
    private
    def xml_content(bug, xpath) 
      if bug.xpath(xpath).first
        bug.xpath(xpath).first.content
      else
        ""
      end
    end
  end
  
  class Comment
    attr_reader :author, :text, :date
    
    def initialize(by, text, date)
      @author = by
      @text = text
      @date = Time.parse(date)
    end
  end
end