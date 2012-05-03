#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Door < Spot
        #
        def initialize n, p=nil
            super n, p
            @saved = nil
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
        def process p
            @viewer.receive p if @viewer
            @saved = p
            receive p
            if not @saved.nil?
                puts "application didn't give that particle back #{p}" if EvenDoors::Twirl.debug
                puts "\t#{p.data EvenDoors::ERROR_FIELD}" if p.action==EvenDoors::ACT_ERROR
                release_p @saved
                @saved = nil
            end
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
