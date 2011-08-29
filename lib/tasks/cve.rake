# ===GLSAMaker v2
#  Copyright (C) 2010 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

libs = %w[ nokogiri ]
libs << File.join(File.dirname(__FILE__), '..', 'bugzilla')
libs << File.join(File.dirname(__FILE__), '..', 'glsamaker')
libs << File.join(File.dirname(__FILE__), 'utils')

#print "About to load libraries\n"
libs.each { |lib| 
#	print "Loading #{lib}\n"
	require lib 
}

TMPDIR = File.join(File.dirname(__FILE__), '..', '..', 'tmp')
# What year are the first CVEs from?
YEAR = 2004
BASEURL = "http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-%s.xml"

DEBUG   = ENV.has_key? 'DEBUG'
VERBOSE = ENV.has_key?('VERBOSE') or DEBUG
QUIET   = ENV.has_key? 'QUIET'

raise "I can't be quiet and verbose at the same time..." if QUIET and VERBOSE

namespace :cve do
  desc "Full CVE data import"
  task :full_import => [:environment, "db:load_config"] do
    start_ts = Time.now

    (YEAR..Date.today.year).each do |year|
      info "Processing CVEs from ".bold + year.to_s.purple

      xmldata = status "Downloading" do
        Glsamaker::HTTP.get(BASEURL % year)
      end

      xml = status "Loading XML" do
        Nokogiri::XML(xmldata)
      end

      #xml = status "Loading cached XML from a file" do
      # Nokogiri::XML(File.open('/Users/alex/Desktop/nvdcve-2.0-2004.xml'))
      #end

      namespace = {'cve' => 'http://scap.nist.gov/schema/feed/vulnerability/2.0'}
      processed_cves = 0
      cpe_cache = {}

      cves = xml.root.xpath('cve:entry', namespace)
      info "#{cves.size.to_s.purple} CVEs (one dot equals 100, purple dot equals 500)"

      cves.each do |cve|
        unless VERBOSE or QUIET

          if processed_cves % 500 == 0
            print ".".purple
          else
            print "." if processed_cves % 100 == 0
          end
        end

        puts cve['id'].to_s.purple if VERBOSE

        begin
          create_cve(cve)
        rescue ActiveRecord::StatementInvalid => e
          # Ignore dupes, ONLY do that for the full db update!
          raise e unless e.message =~ /Duplicate entry/
        end

        processed_cves += 1
        STDOUT.flush
      end

      puts
    end

    info "done".green
    info "(#{Time.now - start_ts} seconds)"
  end

  desc "Incremental CVE data update"
  task :update => :environment do
    start_ts = Time.now
    info "Running incremental CVE data update..."

    xmldata = status "Downloading" do
      Glsamaker::HTTP.get(BASEURL % 'modified')
    end

    xml = status "Loading XML" do
      Nokogiri::XML(xmldata)
    end

    namespace = {'cve' => 'http://scap.nist.gov/schema/feed/vulnerability/2.0'}
    processed_cves = created_cves = updated_cves = 0
    cpe_cache = {}

    cves = xml.root.xpath('cve:entry', namespace)
    info "#{cves.size.to_s.purple} CVEs (one dot equals 100, purple dot equals 500)"

    cves.each do |cve|
      unless VERBOSE or QUIET
        if processed_cves % 500 == 0
          print ".".purple
        else
          print "." if processed_cves % 100 == 0
        end
      end

      puts cve['id'].to_s.purple if VERBOSE

      c = Cve.find_by_cve_id cve['id']

      if c == nil
        debug "Creating CVE."
        create_cve(cve)
        created_cves += 1
      else
        last_changed_at = Time.parse(cve.xpath('vuln:last-modified-datetime').first.content).utc
        db_lca = c.last_changed_at
        
        if last_changed_at.to_i > c.last_changed_at.to_i          
          debug "Updating CVE. Timestamp changed."
          summary = cve.xpath('vuln:summary').first.content
          c.attributes = {
            :cve_id => cve['id'],
            :summary => summary,
            :cvss => cvss_xml2str(cve.xpath('vuln:cvss')),
            :published_at => DateTime.parse(cve.xpath('vuln:published-datetime').first.content),
            :last_changed_at => DateTime.parse(cve.xpath('vuln:last-modified-datetime').first.content),
          }

          c.state = 'REJECTED' if summary =~ /^\*\* REJECT \*\*/
          c.save!

          db_references = []
          xml_references = []
          cve.xpath('vuln:references').each do |ref|
            xml_references << [
              ref.xpath('vuln:source').first.content,
              ref.xpath('vuln:reference').first.content,
              ref.xpath('vuln:reference').first['href']
            ]
          end
          
          c.references.each do |ref|
            db_references << [ref.source, ref.title, ref.uri]
          end
          
          rem = db_references - xml_references
          debug "Removing references: #{rem.inspect}"
          
          rem.each do |item|
            ref = c.references.where(['source = ? AND title = ? AND uri = ?', *item]).first
            c.references.delete(ref)
            ref.destroy
          end
          
          add = xml_references - db_references
          debug "Ading references:    #{add.inspect}"
          
          add.each do |item|
            c.references.create(
              :source => item[0],
              :title =>  item[1],
              :uri =>    item[2]
            )
          end

          db_cpes = []
          xml_cpes = []
          cve.xpath('vuln:vulnerable-software-list/vuln:product').each do |prod|
            xml_cpes << prod.content
          end
          
          c.cpes.each do |prod|
            db_cpes << prod.cpe
          end
          
          rem = db_cpes - xml_cpes
          debug "Removing CPEs: #{rem.inspect}"
          
          rem.each do |item|
            c.cpes.delete(Cpe.find_by_cpe(item))
          end
          
          add = xml_cpes - db_cpes
          debug "Ading CPEs:    #{add.inspect}"
          
          add.each do |item|
            cpe = Cpe.where(:cpe => item).first
            cpe ||= Cpe.create(:cpe => item)

            c.cpes << cpe
          end
          
          c.save!
          updated_cves += 1
        end
      end

      processed_cves += 1
      STDOUT.flush
    end

    info ""

    info "(#{Time.now - start_ts} seconds, #{created_cves} new CVE entries, #{updated_cves} updated CVE entries)"
  end

  desc "Import CVE resolutions from the old CVE tool"
  task :oldimport => :environment do

    file = status "Downloading" do
      Glsamaker::HTTP.get("http://overlays.gentoo.org/svn/proj/security/data/CVE/list")
    end

    $saved_cve = {:id => "", :bugs => []}
    sys_usr = User.find(0)

    file.each_line do |l|
      # Start a new entry
      if l[0..2] == "CVE"
        # Save the old entry before starting a new one
        unless $saved_cve[:id] == ""
          #
          # Public Service Announcement:
          # IN THE FOLLOWING CODE BLOCK: DO *NEVER* ADD ANY `next' STATEMENTS!
          #                                                           -a3li
          debug "CVE: #{$saved_cve[:id]}. Bugs: #{$saved_cve[:bugs].inspect}. State: #{$saved_cve[:state]}. Reason: #{$saved_cve[:reason]}"
          c = Cve.find_by_cve_id($saved_cve[:id])
          c = nil if $saved_cve[:skip]

          if c == nil
            $stderr.puts "#{$saved_cve[:id]} not found in the CVE databse OR forced skip. Skipping."
          else

            state = $saved_cve[:state]
            state ||= "NEW"

            if $saved_cve.has_key? :note
              c.comments.create(
                :user_id => 0,
                :comment => $saved_cve[:note]
             )
            end

            unless state == "NEW"
              $saved_cve[:bugs].each do |bug|
                c.assign(bug, sys_usr)
              end

              if state == "NFU"
                c.nfu(sys_usr, $saved_cve[:reason])
              end

              if state == "REJECTED"
                c.invalidate(sys_usr, "REJECTED")
              end
            end
          end
        end

        l.match /^(CVE-\d{4}-\d{4})/
        $saved_cve = {:id => $1, :bugs => []}
        next
      end

      # We ignore reserved, as NVD doesn't support it.
      if l =~ /^\tRESERVED$/
        $saved_cve[:skip] = true
        $saved_cve[:state] = "RESERVED"
        next
      end

      if l =~ /^\tREJECTED$/
        $saved_cve[:state] = "REJECTED"
        next
      end

      if l =~ /^\tNOT-FOR-US: (.*)$/
        $saved_cve[:state] = "NFU" unless $saved_cve[:state] == "REJECTED"
        $saved_cve[:reason] = $1
        next
      end

      if l =~ /^\tBUG: (\d+)$/
        $saved_cve[:bugs] << Integer($1)
        $saved_cve[:state] = "ASSIGNED"
        next
      end

      if l =~ /^\tTODO: check$/
        $saved_cve[:state] = "NEW"
        next
      end

      if l =~ /^\tTODO: (.*)$/
        if $1 == 'check-old'
          $saved_cve[:state] = "NFU"
          $saved_cve[:reason] = $1
        else
          $saved_cve[:state] = "NEW"
          $saved_cve[:note] = $1
        end
        next
      end

      if l =~ /^\tNOTE: (.*)$/
        $saved_cve[:note] = $1
        next
      end

      puts "XXX: #{l}"
      break
    end # each line

  end # task

end # namespace cve

# Misc. functions

# Run something, and display a status info around it
def status(message)
  unless block_given?
    raise ArgumentError, "I want a block :("
  end

  print "#{message}....." unless QUIET
  STDOUT.flush

  stuff = yield
  print "\b" * 5 + " done.".green + "\n" unless QUIET
  stuff
end

def debug(msg)
  $stderr.puts msg if DEBUG
end

def info(msg)
  puts msg unless QUIET
end

# 7.2/AV:L/AC:L/Au:N/C:C/I:C/A:C
def cvss_xml2str(data)
  def get_content(x, y)
    x.xpath(y).first.content
  end

  return nil if data.size == 0

  str  = "#{get_content(data, 'cvss:base_metrics/cvss:score')}/"
  str += "AV:#{get_content(data, 'cvss:base_metrics/cvss:access-vector')[0,1]}/"
  str += "AC:#{get_content(data, 'cvss:base_metrics/cvss:access-complexity')[0,1]}/"
  str += "Au:#{get_content(data, 'cvss:base_metrics/cvss:authentication')[0,1]}/"
  str += "C:#{get_content(data, 'cvss:base_metrics/cvss:confidentiality-impact')[0,1]}/"
  str += "I:#{get_content(data, 'cvss:base_metrics/cvss:integrity-impact')[0,1]}/"
  str += "A:#{get_content(data, 'cvss:base_metrics/cvss:availability-impact')[0,1]}"

  str
end

def create_cve(cve)
  summary = cve.xpath('vuln:summary').first.content
  _cve = Cve.create(
    :cve_id => cve['id'],
    :summary => summary,
    :cvss => cvss_xml2str(cve.xpath('vuln:cvss')),
    :published_at => DateTime.parse(cve.xpath('vuln:published-datetime').first.content),
    :last_changed_at => DateTime.parse(cve.xpath('vuln:last-modified-datetime').first.content),
    :state => (summary =~ /^\*\* REJECT \*\*/ ? 'REJECTED' : 'NEW')
  )

  cve.xpath('vuln:references').each do |ref|
    CveReference.create(
      :cve => _cve,
      :source => ref.xpath('vuln:source').first.content,
      :title => ref.xpath('vuln:reference').first.content,
      :uri => ref.xpath('vuln:reference').first['href']
    )
  end

  cve.xpath('vuln:vulnerable-software-list/vuln:product').each do |prod|
    cpe_str = prod.content

    cpe = Cpe.where(:cpe => cpe_str).first
    cpe ||= Cpe.create(:cpe => cpe_str)

    _cve.cpes << cpe
  end
end
