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
            raise EvenDoors::Exception.new "Spot name #{name} is not valid" if @name.include? EvenDoors::PATH_SEP
        end
        #
        attr_reader :name
        attr_accessor :viewer, :parent
        #
        def path
            return @path if @path
            @path = ( @parent ? @parent.path+EvenDoors::PATH_SEP : '') + name
        end
        #
    end
    #
end
#
# EOF
