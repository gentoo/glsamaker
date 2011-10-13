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

require 'bugzilla'

module Glsamaker
  module Bugs
  
    module StatusMixin
      def secbug_status
        if whiteboard =~ /([A-C~?][0-4?]\??)\s+\[(.*?)\]\s*?(.*?)$/
          st = []
          
          $2.split("/").each do |status|
            st << Status.new(status)
          end
          
          return st
        else
          [Status.new('?')]
        end
      end
    end
    
    module ArchesMixin
      # Returns an array of all arch teams in CC
      def arch_cc
        @arch_cc ||= _arch_cc
      end
      
      private
      def _arch_cc
        ccd_arches = []
        our_arches = %w[ alpha@gentoo.org amd64@gentoo.org arm@gentoo.org bsd@gentoo.org hppa@gentoo.org 
          ia64@gentoo.org m68k@gentoo.org mips@gentoo.org ppc64@gentoo.org ppc@gentoo.org release@gentoo.org 
          s390@gentoo.org sh@gentoo.org sparc@gentoo.org x86@gentoo.org ]
        
        if cc.is_a? String
          _cc = cc.split(/,\s*/)
        elsif cc.nil?
          _cc = []
        else
          _cc = cc
        end
        
        _cc.each do |cc_member|
          if our_arches.include? cc_member
            ccd_arches << cc_member
          end
        end
        
        ccd_arches
      end
    end
    
    module BugReadyMixin
      # Indicates whether this bug has been handled and is in the correct
      # state for sending a GLSA assigned to it.
      def bug_ready?
        secbug_status.each do |s|
          return false unless s.status == :glsa and not s.pending?
        end

        return arch_cc == []
      rescue Exception => e
        return false
      end
    end
  
    # Extends Bugzilla::Bug with the Status and Arches functionality
    class Bug < Bugzilla::Bug
      def whiteboard
        @status_whiteboard
      end
      
      def cc
        @cc
      end

      # Returns the Gentoo Bugzilla URI for the bug.
      # Set +secure+ to false to get a HTTP instead of a HTTPS URI
      def bug_url(secure = true)
        if secure
          "https://#{GLSAMAKER_BUGZIE_HOST}/show_bug.cgi?id=#{self.bug_id}"
        else
          "http://#{GLSAMAKER_BUGZIE_HOST}/show_bug.cgi?id=#{self.bug_id}"
        end
      end

      include StatusMixin
      include ArchesMixin
      include BugReadyMixin
    end
    
    # This baby is a bug status, one of the things you see in squared brackets in whiteboards.
    class Status
      include Comparable
      
      attr_reader :status
      
      # Creates a new Status object by parsing +str+ as a single status string
      def initialize(str)
        if str == '?'
          @status = '?'.to_sym
          @blocked = @overdue = @pending = false
          return
        end
        
        cmp = str.strip.split(/\s+/)
        
        if cmp.length == 2
          @blocked = (cmp[1] == "blocked")
        end
        
        if cmp[0] =~ /^(upstream|ebuild|stable|glsa|noglsa)(\+|\?|\+\?|\?\+)?$/
          @overdue = ($2 != nil and $2.include? "+")
          @pending = ($2 != nil and $2.include? "?")
          
          @status = $1.downcase.to_sym
        else
          raise ArgumentError, "Malformed Status string: #{str}"
        end   
      end
      
      # Returns +true+ if the bug is blocked by another (c.f. +'blocked'+ in whiteboards)
      def blocked?
        @blocked
      end
      
      # Returns +true+ if the bug is overdue (cf. +'+'+ in whiteboards)
      def overdue?
        @overdue
      end
      
      # Returns +true+ if the bug is pending action (cf. +'?'+ in whiteboards) 
      def pending?
        @pending
      end
      
      # Returns a string representation (like you would find it in the whiteboard)
      def to_s
        @status.to_s + (@overdue ? "+" : "") + (@pending ? "?" : "") + (@blocked ? " blocked" : "")
      end
      
      # Comparison
      def <=>(other)
        raise(ArgumentError, "Cannot compare to #{other.class}") unless other.is_a? Status
        
        s = ['?'.to_sym, :upstream, :ebuild, :stable, :glsa, :noglsa]
        
        if other.status == @status
          if other.pending? == @pending and other.overdue? == @overdue
            0
          else
            if other.overdue? and not @overdue
              -1
            elsif @overdue and not other.overdue?
              1
            else
              if @pending and not other.pending?
                -1
              else
                1
              end
            end
          end
        else
          (s.index(@status) - s.index(other.status)) < 0 ? -1 : 1
        end
      end

    end
  end
end
