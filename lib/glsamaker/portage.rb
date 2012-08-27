# ===GLSAMaker v2
#  Copyright (C) 2009-2011 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2009 Pierre-Yves Rofes <py@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

require 'nokogiri'

module Glsamaker
  # Helper functions for Portage tree interaction
  module Portage
    
    # Package description helper
    class Description
      class << self
        # Tries to fetch the description for the package +atom+ from
        # an ebuild's entry (works if running on Gentoo)
        def ebuild(atom)
          raise(ArgumentError, "Invalid package atom") unless Portage.valid_atom?(atom)
          nil
        end

        def eix(atom)
          nil
        end

        # Loads a description for +atom+ from packages.gentoo.org
        def pgo(atom)
          raise(ArgumentError, "Invalid package atom") unless Portage.valid_atom?(atom)

          n = Nokogiri::XML(Glsamaker::HTTP.get("http://packages.gentoo.org/package/#{atom}"))

          node = n.css('p.description').first.children.first
          if node.type == Nokogiri::XML::Node::TEXT_NODE
            node.to_s
          else
            raise ArgumentError, "XML parse error"
          end
        end

        # Loads a description for +atom+ from Google
        def google(atom)
          nil
        end
      end
    end
    
    module_function
    # Returns the location of the portage dir, or raises an exception if it cannot be found
    def portdir
      unless File.directory? GLSAMAKER_PORTDIR
        raise "GLSAMAKER_PORTDIR is not a directory"
      end
      
      GLSAMAKER_PORTDIR
    end
    
    # Validates the atom +atom+
    def valid_atom?(atom)
      atom =~ /^[+a-zA-Z0-9_-]+\/[+a-zA-Z0-9_-]+$/
    end

    # Checks if there are any ebuilds for the +atom+
    def has_ebuilds?(atom)
      return false unless valid_atom? atom

      Dir.chdir("#{portdir}/#{atom}") do
        Dir.glob('*.ebuild') do |ebuild|
          return true
        end
      end

      false
    rescue Errno::ENOENT
      false
    end
    
    # Gets a description
    def get_description(atom)
      Description.eix(atom) ||
      Description.ebuild(atom) ||
      Description.pgo(atom) ||
      Description.google(atom) ||
      "[could not get a description]"
    end
    
    # Returns package atoms that match +re+
    def find_packages(re)
      results = []
      
      Dir.chdir(portdir) do
        Dir.glob('*-*') do |cat|
          Dir.chdir(cat) do
            Dir.glob("*") do |pkg|
              pkg =~ re and results << "#{cat}/#{pkg}"
            end
          end
        end
      end
      
      results
    end
    
    # Returns an array of maintainer email addresses for the package +atom+
    def get_maintainers(atom)
      raise(ArgumentError, "Invalid package atom") unless Portage.valid_atom?(atom)
      raise(ArgumentError, "Cannot find metadata") unless File.exist? File.join(portdir, atom, 'metadata.xml')
      
      x = Nokogiri::XML(File.read(File.join(portdir, atom, 'metadata.xml')))
      
      herds = []
      maintainers = []
      
      x.xpath('/pkgmetadata/herd').each {|h| herds << h.content }
      x.xpath('/pkgmetadata/maintainer/email').each {|m| maintainers << m.content }
      
      unless herds.first == "no-herd"
        herds_xml = Nokogiri::XML(File.read(File.join(portdir, 'metadata', 'herds.xml')))
        herds_email = herds.map {|h| herds_xml.xpath("/herds/herd/name[text()='#{h}']").first.parent.xpath("./email").first.content }
        
        (maintainers + herds_email).uniq
      else
        maintainers
      end
    end
    
    # Returns information from the portage metadata cache
    # Values: :depend, :rdepend, :slot, :src_uri, :restrict, :homepage,
    # :license, :description, :keywords, :iuse, :required_use,
    # :pdepend, :provide, :eapi, :properties, :defined_phases
    # as per portage/pym/portage/cache/metadata.py (database.auxdbkey_order)
    #
    # @param [String] atom Package atom (without version, see next parameter)
    # @param [String] version Desired version, tries to use the last available one (as decided by a rather stupid technique)
    # @return [Hash{Symbol => String, Array}] A hash with all available metadata (see above for keys)
    def get_metadata(atom, version = :latest)
      raise(ArgumentError, "Invalid package atom") unless Portage.valid_atom?(atom)
      raise(ArgumentError, "Invalid version string") if version.to_s.include? '..'

      items = {
          'DEFINED_PHASES' => :defined_phases,
          'DEPEND'         => :depend,
          'DESCRIPTION'    => :description,
          'EAPI'           => :eapi,
          'HOMEPAGE'       => :homepage,
          'IUSE'           => :iuse,
          'KEYWORDS'       => :keywords,
          'LICENSE'        => :license,
          'PDEPEND'        => :pdepend,
          'PROPERTIES'     => :properties,
          'RDEPEND'        => :rdepend,
          'RESTRICT'       => :restrict,
          'REQUIRED_USE'   => :required_use,
          'SLOT'           => :slot,
          'SRC_URI'        => :src_uri
      }

      valid_keys = items.keys

      # List of metadata items to split at space
      split_keys = ['SRC_URI', 'IUSE', 'KEYWORDS', 'PROPERTIES', 'DEFINED_PHASES']

      cat, pkg = atom.split('/', 2)
      r = Regexp.compile('^(\\w+)=([^\n]*)')
      result = {}
      
      Dir.chdir(File.join(Glsamaker::Portage.portdir, 'metadata', 'md5-cache', cat)) do
        if version == :latest
          f = File.open(Dir.glob("#{pkg}-[0-9]*").last, 'r')
        else
          f = File.open(File.join("#{pkg}-#{version}"), 'r')
        end
        
        while f.gets
          if (match = r.match($_)) != nil and valid_keys.include? match[1]
            if split_keys.include? match[1]
              result[items[match[1]]] = match[2].split(' ')
            else
              result[items[match[1]]] = match[2]
            end
          end
        end
        
        f.close
      end
      result
    end
  end
  
end
