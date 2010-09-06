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
libs << File.join(File.dirname(__FILE__), '..', 'glsamaker')
libs << File.join(File.dirname(__FILE__), 'utils')

libs.each { |lib| require lib }

TMPDIR = File.join(File.dirname(__FILE__), '..', '..', 'tmp')
# What year are the first CVEs from?
YEAR = 2004
BASEURL = "http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-%s.xml"

VERBOSE = (ENV['VERBOSE'] == "1")

namespace :cve do
  desc "Full CVE data import"
  task :full_import => :environment do

    unless File.writable?(TMPDIR)
      puts "!!!".red + " I need write permissions on " + File.expand_path(TMPDIR).bold
      raise "Temporary directory not writeable"
    end

    start_ts = Time.now

    (YEAR..Date.today.year).each do |year|
      puts "Processing CVEs from ".bold + year.to_s.purple

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
      puts "#{cves.size.to_s.purple} CVEs (one dot equals 100, purple dot equals 500)"

      cves.each do |cve|
        unless VERBOSE

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

    puts "done".green
    puts "(#{Time.now - start_ts} seconds)"
  end

  desc "Incremental CVE data update"
  task :update => :environment do
    start_ts = Time.now
    puts "Running incremental CVE data update..."

    xmldata = status "Downloading" do
      Glsamaker::HTTP.get(BASEURL % 'modified')
    end

    xml = status "Loading XML" do
      Nokogiri::XML(xmldata)
    end

    namespace = {'cve' => 'http://scap.nist.gov/schema/feed/vulnerability/2.0'}
    processed_cves = 0
    cpe_cache = {}

    cves = xml.root.xpath('cve:entry', namespace)
    puts "#{cves.size.to_s.purple} CVEs (one dot equals 100, purple dot equals 500)"

    cves.each do |cve|
      unless VERBOSE
        if processed_cves % 500 == 0
          print ".".purple
        else
          print "." if processed_cves % 100 == 0
        end
      end

      puts cve['id'].to_s.purple if VERBOSE

      c = CVE.find_by_cve_id cve['id']

      if c == nil
        create_cve(cve)
      else
        last_changed_at = DateTime.parse(cve.xpath('vuln:last-modified-datetime').first.content)

        if last_changed_at > c.last_changed_at
          summary = cve.xpath('vuln:summary').first.content
          c.attributes = {
            :cve_id => cve['id'],
            :summary => summary,
            :cvss => cvss_xml2str(cve.xpath('vuln:cvss')),
            :published_at => DateTime.parse(cve.xpath('vuln:published-datetime').first.content),
            :last_changed_at => DateTime.parse(cve.xpath('vuln:last-modified-datetime').first.content),
          }

          c.state = 'REJECTED' if summary =~ /^\*\* REJECT \*\*/

          cve.xpath('vuln:references').each do |ref|
            
            CVEReference.create(
              :cve => _cve,
              :source => ref.xpath('vuln:source').first.content,
              :title => ref.xpath('vuln:reference').first.content,
              :uri => ref.xpath('vuln:reference').first['href']
            )
          end

          cve.xpath('vuln:vulnerable-software-list/vuln:product').each do |prod|
            cpe_str = prod.content

            cpe = CPE.find(:first, :conditions => ['cpe = ?', cpe_str])
            cpe ||= CPE.create(:cpe => cpe_str)

            _cve.cpes << cpe
          end

        end
      end

      processed_cves += 1
      STDOUT.flush
    end

    puts

    puts "done".green
    puts "(#{Time.now - start_ts} seconds)"
  end

end

# Misc. functions

def status(message)
  unless block_given?
    raise ArugmentError, "I want a block :("
  end

  print "#{message}....."
  STDOUT.flush

  stuff = yield
  print "\b" * 5 + " done.".green + "\n"
  stuff
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
  _cve = CVE.create(
    :cve_id => cve['id'],
    :summary => summary,
    :cvss => cvss_xml2str(cve.xpath('vuln:cvss')),
    :published_at => DateTime.parse(cve.xpath('vuln:published-datetime').first.content),
    :last_changed_at => DateTime.parse(cve.xpath('vuln:last-modified-datetime').first.content),
    :state => (summary =~ /^\*\* REJECT \*\*/ ? 'REJECTED' : 'NEW')
  )

  cve.xpath('vuln:references').each do |ref|
    CVEReference.create(
      :cve => _cve,
      :source => ref.xpath('vuln:source').first.content,
      :title => ref.xpath('vuln:reference').first.content,
      :uri => ref.xpath('vuln:reference').first['href']
    )
  end

  cve.xpath('vuln:vulnerable-software-list/vuln:product').each do |prod|
    cpe_str = prod.content

    cpe = CPE.find(:first, :conditions => ['cpe = ?', cpe_str])
    cpe ||= CPE.create(:cpe => cpe_str)

    _cve.cpes << cpe
  end
end
