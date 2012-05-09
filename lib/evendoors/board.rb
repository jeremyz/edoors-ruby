#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Board < Door
        #
        def initialize n, p=nil
            super n, p
            @postponed = {}
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
                puts "#{path} didn't give that particle back #{p}" if EvenDoors::Twirl.debug_errors
                puts "\t#{p.data EvenDoors::ERROR_FIELD}" if p.action==EvenDoors::ACT_ERROR
                release_p @saved
                @saved = nil
            end
        end
        #
    end
    #
end
#
# EOF
