require 'nokogiri'
require 'fastercsv'

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
        xml = Nokogiri::XML(Glsamaker::HTTP.get("http://bugs.gentoo.org/show_bug.cgi?ctype=xml&id=#{id}"))
      rescue Exception => e
        raise ArgumentError, "Couldn't load bug: #{e.message}"
      end
      
      self.new(xml.root.xpath("bug").first)
    end
    
    def self.str2bugIDs(str)
      bug_ids = str.split(/,\s*/)

      bug_ids.map do |bug|
        bug.gsub(/\D/, '')
      end
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
  
  # Looks on bugzilla for all bugs that are in the [glsa] state
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
  
end