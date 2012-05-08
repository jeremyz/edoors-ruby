#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Spot
        #
        def initialize n, p
            @name   = n     # unique in it's room
            @parent = p     # single direct parent
            @viewer = nil   # particle going through that position will be sent there readonly
        end
        #
        attr_reader :name
        attr_accessor :viewer, :parent
        #
        def path
            return @path if @path
            p = ( @parent ? @parent.path+'/' : '') + name
            @path = p.sub(/^\/+/,'').sub(/\/+$/,'').gsub(/\/{2,}/,'/')
        end
        #
    end
    #
end
#
# EOF
