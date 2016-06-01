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
require 'fastercsv'
require 'fileutils'
require 'xmlrpc/client'

module Bugzilla ; end

%w[ comment history bug ].each {|lib| require File.join(File.dirname(__FILE__), "bugzilla/#{lib}")}

# Bugzilla module
module Bugzilla
  module_function
  # Adds a comment to a bug. Returns the comment id on success, raises an exception on failure.
  def add_comment(bug, comment)
    if GLSAMAKER_BUGZIE_SKIP
      Rails.logger.info 'Skipped Bugzilla.add_comment'
      return
    end

    Rails.logger.debug 'Called Bugzilla.add_comment'
    did_retry = false

    begin
      client, token = xmlrpc_client

      result = client.call('Bug.add_comment', {
          'id' => bug.to_i,
          'comment' => comment,
          'Bugzilla_token' => token,
      })
      result['id']
    rescue XMLRPC::FaultException => e
      if did_retry
        raise "Could not add the comment: #{e.faultString} (code #{e.faultCode})"
      end

      # If we need to log in first
      if e.faultCode == 410
        Rails.logger.debug "Not logged in, doing that now."
        log_in
        did_retry = true
        retry
      else
        raise "Could not add the comment: #{e.faultString} (code #{e.faultCode})"
      end
    end

  end

  # Updates a bug. Returns an array of changes that were done on the bug.
  def update_bug(bug, changes = {})
    if GLSAMAKER_BUGZIE_SKIP
      Rails.logger.info 'Skipped Bugzilla.update_bug'
      return
    end

    Rails.logger.debug 'Called Bugzilla.update_bug'
    did_retry = false

    begin
      client, token = xmlrpc_client

      rpc_data = {}
      rpc_data['ids'] = [bug]
      rpc_data['component'] = changes[:component] if changes.has_key?(:component)
      rpc_data['product'] = changes[:product] if changes.has_key?(:product)
      rpc_data['summary'] = changes[:summary] if changes.has_key?(:summary)
      rpc_data['version'] = changes[:version] if changes.has_key?(:version)
      rpc_data['comment'] = {'body' => changes[:comment]} if changes.has_key?(:comment)
      rpc_data['priority'] = changes[:priority] if changes.has_key?(:priority)
      rpc_data['severity'] = changes[:severity] if changes.has_key?(:severity)
      rpc_data['alias'] = changes[:alias] if changes.has_key?(:alias)
      rpc_data['assigned_to'] = changes[:assignee] if changes.has_key?(:assignee)
      #rpc_data['cc'] = changes[:cc].to_a if changes.has_key?(:cc) TODO: add and remove
      rpc_data['status'] = changes[:status] if changes.has_key?(:status)
      rpc_data['whiteboard'] = changes[:whiteboard] if changes.has_key?(:whiteboard)
      rpc_data['url'] = changes[:url] if changes.has_key?(:url)
      rpc_data['resolution'] = changes[:resolution] if changes.has_key?(:resolution)
      rpc_data['Bugzilla_token'] = token

      result = client.call('Bug.update', rpc_data)
      result['bugs'].first
    rescue XMLRPC::FaultException => e
      if did_retry
        raise "Could not file the bug: #{e.faultString} (code #{e.faultCode})"
      end

      # If we need to log in first
      if e.faultCode == 410
        Rails.logger.debug "Not logged in, doing that now."
        log_in
        did_retry = true
        retry
      else
        raise "Could not file the bug: #{e.faultString} (code #{e.faultCode})"
      end
    end
  end

  # Files a bug, and returns the id of the filed bug
  def file_bug(data)
    if GLSAMAKER_BUGZIE_SKIP
      Rails.logger.info 'Skipped Bugzilla.file_bug'
      return
    end

    Rails.logger.debug 'Called Bugzilla.file_bug'
    did_retry = false

    begin
      client, token = xmlrpc_client

      rpc_data = {}
      rpc_data['component'] = data[:component] if data.has_key?(:component)
      rpc_data['product'] = data[:product] if data.has_key?(:product)
      rpc_data['summary'] = data[:summary] if data.has_key?(:summary)
      rpc_data['version'] = data[:version] if data.has_key?(:version)
      rpc_data['description'] = data[:comment] if data.has_key?(:comment)
      rpc_data['priority'] = data[:priority] if data.has_key?(:priority)
      rpc_data['severity'] = data[:severity] if data.has_key?(:severity)
      rpc_data['alias'] = data[:alias] if data.has_key?(:alias)
      rpc_data['assigned_to'] = data[:assignee] if data.has_key?(:assignee)
      rpc_data['cc'] = data[:cc].to_a if data.has_key?(:cc)
      rpc_data['status'] = data[:status] if data.has_key?(:status)
      rpc_data['Bugzilla_token'] = token

      result = client.call('Bug.create', rpc_data)
      result['id']
    rescue XMLRPC::FaultException => e
      if did_retry
        raise "Could not file the bug: #{e.faultString} (code #{e.faultCode})"
      end

      # If we need to log in first
      if e.faultCode == 410
        Rails.logger.debug "Not logged in, doing that now."
        log_in
        did_retry = true
        retry
      else
        raise "Could not file the bug: #{e.faultString} (code #{e.faultCode})"
      end
    end
  end

  def log_in
    Rails.logger.debug "Called Bugzilla.log_in"
    raise unless GLSAMAKER_BUGZIE_USER and GLSAMAKER_BUGZIE_PW

    client, token = xmlrpc_client

    begin
      result = client.call('User.login', {
          'login' => GLSAMAKER_BUGZIE_USER,
          'password' => GLSAMAKER_BUGZIE_PW
      })

      Rails.logger.debug "Successfully logged in. UID: #{result['id']}"

      token_file = File.join(Rails.root, 'tmp', 'bugzie-token.txt')
      FileUtils.rm(token_file) if File.exist?(token_file)
      FileUtils.touch(token_file)
      File.chmod(0600, token_file)
      File.open(token_file, 'w') {|f| f.write result['token'] }

      return true
    rescue XMLRPC::FaultException => e
      Rails.logger.warn "Failure logging in: #{e.message}"
      return false
    end
  end

  def xmlrpc_client
    client = XMLRPC::Client.new(GLSAMAKER_BUGZIE_HOST, '/xmlrpc.cgi', 443, nil, nil, nil, nil, true)
    client.http_header_extra = {'User-Agent' => "GLSAMaker/#{GLSAMAKER_VERSION} (http://security.gentoo.org/)"}

    token = ''
    token_file = File.join(Rails.root, 'tmp', 'bugzie-token.txt')
    if File.readable? token_file
      token = File.read(token_file)
    end

    [client, token]
  end
end
