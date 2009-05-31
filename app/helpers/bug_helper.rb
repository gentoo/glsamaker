module BugHelper
  
  
  # Creates links around common phrases like <tt>Bug 12345</tt> or <tt>Comment 234</tt>
  def linkify_comment(text)
    text.gsub(/bug (\d+)/i, link_to_function('bug \1', 'buginfo(\1);'))
  end
end
