#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# Copyright 2012 Jérémy Zurcher <jeremy@asynk.ch>
#
# This file is part of edoors-ruby.
#
# edoors-ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# edoors-ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with edoors-ruby.  If not, see <http://www.gnu.org/licenses/>.

#
module Edoors
    #
    ACT_FOLLOW = 'follow'.freeze
    ACT_PASS_THROUGH = 'pass_through'.freeze
    #
    class Board < Door
        #
        # creates a Board object from the arguments.
        #
        # @param [String] n the name of this Board
        # @param [Iota] p the parent
        #
        def initialize n, p
            super n, p
            @postponed = {}
        end
        #
        # called by JSON#generate to serialize the Board object into JSON data
        #
        # @param [Array] a belongs to JSON generator
        #
        def to_json *a
            {
                'kls'       => self.class.name,
                'name'      => @name,
                'postponed' => @postponed
            }.merge(hibernate!).to_json *a
        end
        #
        # creates a Board object from a JSON data
        #
        # @param [Hash] o belongs to JSON parser
        #
        # @raise Edoors::Exception if the json kls attribute is wrong
        #
        def self.json_create o
            raise Edoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            board = self.new o['name'], o['parent']
            o['postponed'].each do |link_value,particle|
                board.process_p Edoors::Particle.json_create(particle.merge!('spin'=>board.spin))
            end
            board.resume! o
            board
        end
        #
        # process the given particle then forward it to user code
        #
        # @param [Particle] p the Particle to be processed
        #
        def process_p p
            @viewer.receive_p p if @viewer
            if p.action!=Edoors::ACT_ERROR and p.action!=Edoors::ACT_PASS_THROUGH
                p2 = @postponed[p.link_value] ||= p
                return if p2==p
                @postponed.delete p.link_value
                p,p2 = p2,p if p.action==Edoors::ACT_FOLLOW
                p.merge! p2
            end
            @saved = p
            receive_p p
            _garbage if not @saved.nil?
        end
        #
        # stores back the given Particle
        #
        # @param [Particle] p the particle to be stored
        #
        # this can be used to prevent the overhead of sending the particle back to self
        #
        def keep! p
            @postponed[p.link_value] = p
            @saved = nil
        end
        #
        # sends away all stored Particle
        #
        def flush!
            while p=@postponed.shift
                send_p p[1]
            end
        end
        #
    end
    #
end
#
# EOF
