# ===GLSAMaker v2
#  Copyright (C) 2010–15 Alex Legler <a3li@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.

libs = %w( nokogiri zlib stringio )
libs << File.join(File.dirname(__FILE__), '..', 'bugzilla')
libs << File.join(File.dirname(__FILE__), '..', 'glsamaker')
libs << File.join(File.dirname(__FILE__), 'utils')

libs.each { |lib| require lib }

TMPDIR = File.join(File.dirname(__FILE__), '..', '..', 'tmp')
# What year are the first CVEs from?
YEAR = (ENV['START_YEAR'] || 2004).to_i
BASEURL = 'https://nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-%s.xml.gz'

DEBUG   = ENV.key? 'DEBUG'
VERBOSE = (ENV.key?('VERBOSE') || DEBUG)
QUIET   = ENV.key? 'QUIET'

fail "I can't be quiet and verbose at the same time..." if QUIET && VERBOSE

namespace :cve do
  desc 'Full CVE data import'
  task full_import: [:environment, 'db:load_config'] do
    start_ts = Time.now

    (YEAR..Date.today.year).each do |year|
      info 'Processing CVEs from '.bold + year.to_s.purple

      xmldata = status 'Downloading' do
        gunzip_str Glsamaker::HTTP.get(BASEURL % year)
      end

      xml = status 'Loading XML' do
        Nokogiri::XML(xmldata)
      end

      namespace = { 'cve' => 'http://scap.nist.gov/schema/feed/vulnerability/2.0' }
      processed_cves = 0
      cpe_cache = {}

      cves = xml.root.xpath('cve:entry', namespace)
      info "#{cves.size.to_s.purple} CVEs (one dot equals 100, purple dot equals 500)"

      cves.each do |cve|
        unless VERBOSE || QUIET

          if processed_cves % 500 == 0
            print '.'.purple
          else
            print '.' if processed_cves % 100 == 0
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

    info 'done'.green
    info "(#{Time.now - start_ts} seconds)"
  end

  desc 'Incremental CVE data update'
  task update: :environment do
    start_ts = Time.now
    info 'Running incremental CVE data update...'

    xmldata = status 'Downloading' do
      gunzip_str Glsamaker::HTTP.get(BASEURL % 'modified')
    end

    xml = status 'Loading XML' do
      Nokogiri::XML(xmldata)
    end

    namespace = { 'cve' => 'http://scap.nist.gov/schema/feed/vulnerability/2.0' }
    processed_cves = created_cves = updated_cves = 0
    cpe_cache = {}

    cves = xml.root.xpath('cve:entry', namespace)
    info "#{cves.size.to_s.purple} CVEs (one dot equals 100, purple dot equals 500)"

    cves.each do |cve|
      unless VERBOSE || QUIET
        if processed_cves % 500 == 0
          print '.'.purple
        else
          print '.' if processed_cves % 100 == 0
        end
      end

      puts cve['id'].to_s.purple if VERBOSE

      c = Cve.find_by_cve_id cve['id']

      if c.nil?
        debug 'Creating CVE.'
        create_cve(cve)
        created_cves += 1
      else
        last_changed_at = Time.parse(cve.xpath('vuln:last-modified-datetime').first.content).utc
        db_lca = c.last_changed_at

        if last_changed_at.to_i > c.last_changed_at.to_i
          debug 'Updating CVE. Timestamp changed.'
          summary = cve.xpath('vuln:summary').first.content
          c.attributes = {
            cve_id: cve['id'],
            summary: summary,
            cvss: cvss_xml2str(cve.xpath('vuln:cvss')),
            published_at: DateTime.parse(cve.xpath('vuln:published-datetime').first.content),
            last_changed_at: DateTime.parse(cve.xpath('vuln:last-modified-datetime').first.content)
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
            debug ref
            c.references.delete(ref)
            ref.destroy
          end

          add = xml_references - db_references
          debug "Ading references:    #{add.inspect}"

          add.each do |item|
            c.references.create(
              source: item[0],
              title:  item[1],
              uri:    item[2]
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
            cpe = Cpe.where(cpe: item).first
            cpe ||= Cpe.create(cpe: item)

            c.cpes << cpe
          end

          c.save!
          updated_cves += 1
        end
      end

      processed_cves += 1
      STDOUT.flush
    end

    info ''

    info "(#{Time.now - start_ts} seconds, #{created_cves} new CVE entries, #{updated_cves} updated CVE entries)"
  end
end

# Run something, and display a status info around it
def status(message)
  fail ArgumentError, 'I want a block :(' unless block_given?

  print "#{message}....." unless QUIET
  STDOUT.flush

  stuff = yield
  print "\b" * 5 + ' done.'.green + "\n" unless QUIET
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
  str += "AV:#{get_content(data, 'cvss:base_metrics/cvss:access-vector')[0, 1]}/"
  str += "AC:#{get_content(data, 'cvss:base_metrics/cvss:access-complexity')[0, 1]}/"
  str += "Au:#{get_content(data, 'cvss:base_metrics/cvss:authentication')[0, 1]}/"
  str += "C:#{get_content(data, 'cvss:base_metrics/cvss:confidentiality-impact')[0, 1]}/"
  str += "I:#{get_content(data, 'cvss:base_metrics/cvss:integrity-impact')[0, 1]}/"
  str += "A:#{get_content(data, 'cvss:base_metrics/cvss:availability-impact')[0, 1]}"

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

def gunzip_str(str)
  Zlib::GzipReader.new(StringIO.new(str)).read
end
