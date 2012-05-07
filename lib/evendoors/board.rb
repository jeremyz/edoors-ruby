#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Board < Spot
        #
        def initialize n, p=nil
            super n, p
            @saved = nil
            @postponed = {}
            @parent.add_spot self if @parent
        end
        #
        def require_p p_kls
            p = EvenDoors::Twirl.require_p p_kls
            p.src = self
            p
        end
        #
        def release_p p
            @saved=nil if @saved==p     # particle is released, all is good
            EvenDoors::Twirl.release_p p
        end
        #
        def process_p p
            @viewer.receive_p p if @viewer
            if p.action!=EvenDoors::ACT_ERROR
                p2 = @postponed[p.link_value] ||= p
                return if p2==p
                @postponed.delete p.link_value
                p,p2 = p2,p if p.action==EvenDoors::ACT_FOLLOW
                p.merge! p2
            end
            @saved = p
            receive_p p
            if not @saved.nil?
                puts "#{path} didn't give that particle back #{p}" if EvenDoors::Twirl.debug
                puts "\t#{p.data EvenDoors::ERROR_FIELD}" if p.action==EvenDoors::ACT_ERROR
                release_p @saved
                @saved = nil
            end
        end
        #
        def process_sys_p p
            # nothing todo with it now
            EvenDoors::Twirl.release_p p
        end
        #
        def send_p p
            p.src = self
            @saved=nil if @saved==p # particle is sent back the data, all is good
            @parent.send_p p        # daddy will know what to do
        end
        #
        def send_sys_p p
            p.src = self
            @saved=nil if @saved==p # particle is sent back the data, all is good
            @parent.send_sys_p p    # daddy will know what to do
        end
        #
    end
    #
end
#
# EOF
