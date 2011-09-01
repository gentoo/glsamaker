class SearchController < ApplicationController
  def index
  end
  
  def results
    search = ThinkingSphinx.search params[:q], :max_matches => 1000, :per_page => 1000
    
    @results = {}
    search.each do |result|
      klass = result.class.to_s
      @results[klass] = [] unless @results.include? klass
      @results[klass] << result
    end
    
    if @results.include? 'Revision'
      @results['Glsa'] = [] unless @results['Glsa']
      
      @results['Revision'].each do |rev|
        @results['Glsa'] << rev.glsa
      end
      
      @results['Glsa'].uniq!
    end

    # Filter search results
    if @results.include? 'Glsa'
      @results['Glsa'].delete_if do |result|
        not check_object_access(result)
      end
    end
  rescue Riddle::ConnectionError => e
    @error = true
  end
end
