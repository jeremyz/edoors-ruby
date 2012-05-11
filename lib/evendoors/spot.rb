#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# Copyright 2012 Jérémy Zurcher <jeremy@asynk.ch>
#
# This file is part of evendoors-ruby.
#
# evendoors-ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# evendoors-ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with evendoors-ruby.  If not, see <http://www.gnu.org/licenses/>.

#
module EvenDoors
    #
    class Spot
        #
        def initialize n, p
            @name   = n     # unique in it's room
            @parent = p     # single direct parent
            @viewer = nil   # particle going through that position will be sent there readonly
            @path = ( @parent ? @parent.path+EvenDoors::PATH_SEP : '') + @name
            @spin = ( @parent ? @parent.spin : self )
            @parent.add_spot self if @parent
            raise EvenDoors::Exception.new "Spot name #{name} is not valid" if @name.include? EvenDoors::PATH_SEP
        end
        #
        attr_reader :name, :path, :spin
        attr_accessor :viewer, :parent
        #
    end
    #
end
#
# EOF
