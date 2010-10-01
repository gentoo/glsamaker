# ===GLSAMaker v2
#  Copyright (C) 2009 Alex Legler <a3li@gentoo.org>
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
  
    class Bug < Bugzilla::Bug    
      def status
        return @status unless @status == nil
        
        if @status_whiteboard =~ /([A-C~][0-4]\??)\s+\[(.*?)\]\s*?(.*?)$/
          
          st = []
          
          $2.split("/").each do |status|
            st << Status.new(status)
          end
        else
          raise ArgumentError, "Malformed whiteboard"
        end
      end
      
      # Returns an array of all arch teams in CC
      def arch_cc
        @arch_cc ||= _arch_cc
      end
      
      private
      def _arch_cc
        arches = []
        our_arches = %w[ alpha@gentoo.org amd64@gentoo.org arm@gentoo.org bsd@gentoo.org hppa@gentoo.org 
          ia64@gentoo.org m68k@gentoo.org mips@gentoo.org ppc64@gentoo.org ppc@gentoo.org release@gentoo.org 
          s390@gentoo.org sh@gentoo.org sparc@gentoo.org x86@gentoo.org ]
        
        @cc.each do |cc|
          if our_arches.include? cc
            arches << cc
          end
        end
        
        arches
      end
    end
    
    # This baby is a bug status, one of the things you see in squared brackets in whiteboards.
    class Status
      include Comparable  
      
      attr_reader :status  
      
      # Creates a new Status object by parsing +str+ as a single status string
      def initialize(str)
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
        
        s = [:dummy, :upstream, :ebuild, :stable, :glsa, :noglsa]
        
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