# Encapsulates a bug's history
class Bugzilla::History
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
class Bugzilla::Change
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
    raise(ArgumentError, "field has to be a symbol") unless field.is_a? Symbol
    
    if @changes.has_key?(field)
      @changes[field][0] += " #{removed}"
      @changes[field][1] += " #{added}"
    else
      @changes[field] = [removed, added]
    end
  end

  # Returns a string representation
  def to_s
    "#{@user} changed at #{@time.to_s}: #{@changes.inspect}"
  end
end