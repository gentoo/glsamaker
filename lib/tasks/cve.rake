# ===GLSAMaker v2
#  Copyright (C) 2010–15 Alex Legler <a3li@gentoo.org>
#  Copyright (C) 2020 Max Magorsch <arzano@gentoo.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# For more information, see the LICENSE file.
libs = %w( json nokogiri zlib stringio )
libs << File.join(File.dirname(__FILE__), '..', 'bugzilla')
libs << File.join(File.dirname(__FILE__), '..', 'glsamaker')
libs << File.join(File.dirname(__FILE__), 'utils')

libs.each { |lib| require lib }

TMPDIR = File.join(File.dirname(__FILE__), '..', '..', 'tmp')
# What year are the first CVEs from?
YEAR = (ENV['START_YEAR'] || 2004).to_i
BASEURL = 'https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-%s.json.gz'

DEBUG   = ENV.key? 'DEBUG'
VERBOSE = (ENV.key?('VERBOSE') || DEBUG)
QUIET   = ENV.key? 'QUIET'

fail "I can't be quiet and verbose at the same time..." if QUIET && VERBOSE

namespace :cve do

  desc 'Destroy all CVEs and CPEs'
  task destroy_all: [:environment, 'db:load_config'] do
    CveReference.destroy_all
    Cve.destroy_all
    Cpe.destroy_all
  end


  desc 'Print all CVEs'
  task print_all: [:environment, 'db:load_config'] do
    Cve.find_each do |cve|
      puts cve.cve_id + ",\"" + cve.summary + "\"," + (cve.cvss || "")  + "," + cve.state + "," + cve.published_at.to_formatted_s(:iso8601) + "," + cve.last_changed_at.to_formatted_s(:iso8601) + "," + cve.created_at.to_formatted_s(:iso8601)  + "," + cve.updated_at.to_formatted_s(:iso8601)
    end
  end


  desc 'Full CVE data import'
  task full_import: [:environment, 'db:load_config'] do
    start_ts = Time.now

    (YEAR..Date.today.year).each do |year|
      info 'Processing CVEs from '.bold + year.to_s.purple

      jsondata = status 'Downloading' do
        gunzip_str Glsamaker::HTTP.get(BASEURL % year)
      end

      json = status 'Loading JSON' do
        JSON.parse(jsondata)
      end

      cves = json["CVE_Items"]
      create_cves(cves)

      puts
    end

    info 'done'.green
    info "(#{Time.now - start_ts} seconds)"
  end


  desc 'Incrementally update last CVEs'
  task update: :environment do

    info 'Running incremental CVE data update...'

    jsondata = status 'Downloading' do
      gunzip_str Glsamaker::HTTP.get(BASEURL % 'modified')
    end

    json = status 'Loading JSON' do
      JSON.parse(jsondata)
    end

    cves = json["CVE_Items"]
    update_cves(cves)
  end


  desc 'Update all CVEs'
  task update_all: :environment do

    info 'Running complete CVE data update...'

    (YEAR..Date.today.year).each do |year|
      info 'Processing CVEs from '.bold + year.to_s.purple

      jsondata = status 'Downloading' do
        gunzip_str Glsamaker::HTTP.get(BASEURL % year)
      end

      json = status 'Loading JSON' do
        JSON.parse(jsondata)
      end

      cves = json["CVE_Items"]
      update_cves(cves)
    end
  end

end


#
# Update the given cve
#
def create_cve(cve)
  summary = cve.dig('cve', 'description', 'description_data', 0, 'value')
  _cve = Cve.create(
    :cve_id => cve.dig('cve', 'CVE_data_meta', 'ID'),
    :summary => summary,
    :cvss => cve.dig('impact', 'baseMetricV2', 'cvssV2', 'vectorString'),
    :published_at => DateTime.parse(cve['publishedDate']),
    :last_changed_at => DateTime.parse(cve['lastModifiedDate']),
    :state => (summary =~ /^\*\* REJECT \*\*/ ? 'REJECTED' : 'NEW')
  )

  if cve.dig('references', 'reference_data')
    cve.dig('references', 'reference_data').each do |ref|
      CveReference.create(
        :cve => _cve,
        :source => ref['refsource'],
        :title => ref['name'],
        :uri => ref['url']
      )
    end
  end

  cve.dig('configurations', 'nodes').each do |node|
    if node.key?('cpe_match')
      node['cpe_match'].each do |cpe_match|
        cpe_str = cpe_match['cpe23Uri']

        cpe = Cpe.where(:cpe => cpe_str).first
        cpe ||= Cpe.create(:cpe => cpe_str)

        _cve.cpes << cpe
      end
    elsif node.key?('children')
      node['children'].each do |child|
        if child.key?('cpe_match')
          child['cpe_match'].each do |cpe_match|
            cpe_str = cpe_match['cpe23Uri']

            cpe = Cpe.where(:cpe => cpe_str).first
            cpe ||= Cpe.create(:cpe => cpe_str)

            _cve.cpes << cpe
          end
        end
      end
    end
  end
end


#
# Create the all given cves
#
def create_cves(cves)
  processed_cves = 0
  info "#{cves.size.to_s.purple} CVEs (one dot equals 100, purple dot equals 500)"

  cves.each do |cve|
    unless VERBOSE || QUIET

      if processed_cves % 500 == 0
        print '.'.purple
      else
        print '.' if processed_cves % 100 == 0
      end
    end

    puts cve.dig('cve', 'CVE_data_meta', 'ID').to_s.purple if VERBOSE

    begin
      create_cve(cve)
    rescue ActiveRecord::StatementInvalid => e
      # Ignore dupes, ONLY do that for the full db update!
      raise e unless e.message =~ /Duplicate entry/
    end

    processed_cves += 1
    STDOUT.flush
  end
end


#
# Update the all given cves
#
def update_cves(cves)
  start_ts = Time.now
  processed_cves = created_cves = updated_cves = 0

  info "#{cves.size.to_s.purple} CVEs (one dot equals 100, purple dot equals 500)"

  cves.each do |cve|
    unless VERBOSE || QUIET
      if processed_cves % 500 == 0
        print '.'.purple
      else
        print '.' if processed_cves % 100 == 0
      end
    end

    puts cve.dig('cve', 'CVE_data_meta', 'ID').to_s.purple if VERBOSE

    c = Cve.find_by_cve_id cve.dig('cve', 'CVE_data_meta', 'ID')

    if c.nil?
      debug 'Creating CVE.'
      create_cve(cve)
      created_cves += 1
    else
      last_changed_at = Time.parse(cve['lastModifiedDate']).utc

      if last_changed_at.to_i > c.last_changed_at.to_i
        debug 'Updating CVE. Timestamp changed.'
        summary = cve.dig('cve', 'description', 'description_data', 0, 'value')
        c.attributes = {
            cve_id: cve.dig('cve','CVE_data_meta','ID'),
            summary: summary,
            cvss: cve.dig('impact', 'baseMetricV2', 'cvssV2', 'vectorString'),
            published_at: DateTime.parse(cve['publishedDate']),
            last_changed_at: DateTime.parse(cve['lastModifiedDate']),
        }

        c.state = 'REJECTED' if summary =~ /^\*\* REJECT \*\*/
        c.save!

        db_references = []
        xml_references = []

        if cve.dig 'references', 'reference_data'
          cve.dig('references', 'reference_data').each do |ref|
            xml_references << [
                :source => ref['refsource'],
                :title => ref['name'],
                :uri => ref['url']
            ]
          end
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

        cve.dig('configurations', 'nodes').each do |node|
          if node.key?('cpe_match')
            node['cpe_match'].each do |cpe_match|
              xml_cpes << cpe_match['cpe23Uri']
            end
          elsif node.key?('children')
            node['children'].each do |child|
              if child.key?('cpe_match')
                child['cpe_match'].each do |cpe_match|
                  xml_cpes << cpe_match['cpe23Uri']
                end
              end
            end
          end
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


#
# Run something, and display a status info around it
#
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

#
# unzip the given string
#
def gunzip_str(str)
  Zlib::GzipReader.new(StringIO.new(str)).read
end
