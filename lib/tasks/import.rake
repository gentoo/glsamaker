require 'rexml/document'
require 'nokogiri'
require 'net/http'
require 'uri'
require 'date'

namespace :import do

  desc "Import Request Files"
  task :requests => :environment do
    info "Importing GLSA requests"

    glsa_req_dir = ENV['GLSA_REQ_DIR']
    if glsa_req_dir == nil
        puts "Please, set GLSA_REQ_DIR"
        exit(-1)
    end

    glsa_list = Array.new
    Glsa.all.each do |glsa|
      glsa_list.push glsa.glsa_id 
    end

    default_user = User.first
    if default_user == nil
        raise "No users defined!"
    end

    Dir.glob(glsa_req_dir + "/*.xml").each do |filename|
        req_f = File.new(filename)
        doc = REXML::Document.new req_f

        root = doc.root
        glsa_req_id = root.attributes['id'][0..7]

        if not glsa_list.include? glsa_req_id
          puts "Processing GLSA Request #{glsa_req_id}"

          glsa = Glsa.new
          glsa.glsa_id = glsa_req_id
          glsa.status = 'request'
          
          root.elements.each('metadata') do |meta|
            user = meta.text.strip
            user = User.where(:login => user)

            if user.length > 0
              user = user[0]
            else
              user = default_user
            end

            glsa.requester = user if meta.attributes['tag'] == 'requester'

          end

          unless glsa.save
            raise "Errors occurred while saving the GLSA object: #{glsa.errors.full_messages.join ', '}"
          end

          root.elements.each('metadata/metadata/metadata') do |comm|
            puts comm.text.strip()

            comment = glsa.comments.new
            comment.user_id = glsa.requester
            comment.rating = 'neutral'
            comment.text = comm.text.strip

            unless comment.save
                raise "Error. #{comment.errors.full_messages.join ', '}"
            end
          end

          #It's time for the revision
          revision = glsa.revisions.new
          revision.revid = 1
          revision.user = glsa.requester
          revision.title = root.elements['title'].text
          revision.impact = root.elements['impact'].attributes['type']
          revision.product = root.elements['product'].attributes['type']
          revision.resolution = root.elements['resolution'].text
          revision.workaround = root.elements['workaround'].text
          revision.description = root.elements['description'].text
          revision.is_release = false
          revision.severity = root.elements['impact'].attributes['type']

          unless revision.save
            #Clean up
            glsa.delete
            raise "Errors occurred while saving the Revision object: #{revision.errors.full_messages.join ', '}"
          end

          #Let's grab the bugs
          root.elements.each('bug') do |bug|
            Bug.create(
              :bug_id => bug.text,
              :revision_id => revision
            )
          end

        end
    end
  end

  desc "Import Advisory Files"
  task :advisories => :environment do
    info "Importing old GLSAs from www.gentoo.org"

    #Lets grab the IDs we have in the DB, the see 
    #if we already processed them
    glsa_list = Array.new
    Glsa.all.each do |glsa|
      glsa_list.push glsa.glsa_id 
    end

    GLSA_URL = "https://www.gentoo.org/rdf/en/glsa-index.rdf"
    GLSA_URL_BASE = "https://www.gentoo.org/security/en/glsa/glsa-%s.xml?passthru=1"

    default_user = User.first
    if default_user == nil
        raise "No users defined!"
    end

    #Let's parse the XML and get the advisories ID
    index = Nokogiri::XML(Glsamaker::HTTP.get(GLSA_URL))
    index.remove_namespaces!
    root_idx = index.root
    ids = Array.new

    root_idx.xpath('item').each do |elem|
      url = elem.at_xpath('./link').content
      elem.at_xpath('./title').content =~ /GLSA\s(\d{6})-(\d{1,3})\s\(.*/
       id = "#{$1}-#{$2}"
       ids << id
    end

    ids.reverse_each do |id|
      #if id no in glsa_list, then process the url
      if not glsa_list.include? id
        puts "Processing GLSA Advisory #{id}"

        xml = index = Nokogiri::XML(Glsamaker::HTTP.get(GLSA_URL_BASE % id))
        root = xml.root

        #Lets create the GLSA in the DB
        glsa = Glsa.new
        glsa.glsa_id = id
        glsa.status = 'release'
        glsa.first_released_at = DateTime.parse(root.at_xpath('./announced').content)

        #Lets take a look at users in Metadata
        root.xpath('metadata').each do |meta|
          user = meta.content.strip()
          user = User.where(:login => user)

          if user.length > 0
            user = user[0]
          else
            user = default_user
          end

          glsa.submitter = user if meta['tag'] == 'submitter'
          glsa.requester = user if meta['tag'] == 'requester'
          glsa.bugreadymaker = user if meta['tag'] == 'bugReady'
        end

        #For old GLSAs with no metadata
        if glsa.submitter == nil
          glsa.submitter = default_user
        end

        if glsa.requester == nil
          glsa.requester = default_user
        end

        unless glsa.save
          raise "Errors occurred while saving the GLSA object: #{glsa.errors.full_messages.join ', '}"
        end

        #Lets create the Revision in the DB
        revision = Revision.new

        revision.glsa = glsa
        revision.user = glsa.submitter
        revision.revid = 1
        revision.release_revision = root.at_xpath('./revised').content.split(':')[1].strip.to_i
        revision.title = root.at_xpath('./title').content
        revision.impact = root.at_xpath('./impact').children.to_xml(:indent => 0)
        revision.product = root.at_xpath('./product').content
        revision.synopsis = root.at_xpath('./synopsis').children.to_xml(:indent => 0)
        revision.resolution = root.at_xpath('./resolution').children.to_xml(:indent => 0)
        revision.workaround = root.at_xpath('./workaround').children.to_xml(:indent => 0)
        revision.description = root.at_xpath('./description').children.to_xml(:indent => 0)
        revision.is_release = true
        revision.severity = root.at_xpath('./impact')['type']

        #Old GLSAs may not have a background tag
        begin
            revision.background = root.at_xpath('./background').content.strip
        rescue
            revision.background = nil
        end

        #Old GLSAs may not have an access tag
        begin
            revision.access = root.at_xpath('./access').content.strip
        rescue
            revision.access = nil
        end

        unless revision.save
          #Clean up
          glsa.delete
          raise "Errors occurred while saving the Revision object: #{revision.errors.full_messages.join ', '}"
        end

        #Let's grab the bugs
        root.xpath('bug').each do |bug|
          revision.bugs.create(
            :bug_id => bug.content.to_i
          )
        end

        #Let's grab the references
        root.xpath('references/uri').each do |uri|
          revision.references.create(
            :url => uri['link'],
            :title => uri.content
          )
        end

        #Let's grab the packages
        root.xpath('affected/package').each do |pkg_info|
          pkg_info.children.each do |inner|
            if inner.is_a? Nokogiri::XML::Node
              auto = true
              if inner['auto'] == 'n'
                auto = false
              end

              revision.packages.create(
                :my_type => inner.node_name,
                :atom => pkg_info['name'],
                :version => inner.content,
                :comp => Package.reverse_comp(inner['range']),
                :arch => pkg_info['arch'],
                :automatic => auto
              )

            end
          end
        end
      end
    end
  end
end
