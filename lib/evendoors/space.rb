#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Space < Room
        #
        def initialize n, args={}
            super n, nil
            EvenDoors::Twirl.debug = args[:debug] || false
        end
        #
        def twirl!
            @spots.values.each do |spot| spot.start! end
            EvenDoors::Twirl.twirl!
            @spots.values.each do |spot| spot.stop! end
        end
        #
    end
    #
end
#
# EOF
