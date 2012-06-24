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
    LNK_SRC     = 'edoors_lnk_src'.freeze
    LNK_DSTS    = 'edoors_lnk_dsts'.freeze
    LNK_KEYS    = 'edoors_lnk_keys'.freeze
    LNK_VALUE   = 'edoors_lnk_value'.freeze
    #
    class Link
        #
        # creates a Link object from the arguments.
        #
        # @param [String] src link source name
        # @param [Array] dsts destinations to apply to the particle on linking success
        # @param [Array] keys keys to apply as link_keys to the particle on linking success
        # @param [Hash] value will be used to check linking with particles
        #
        # @see Room#_try_links try to apply links on a Particle
        # @see Particle#link_with? linking test
        #
        def initialize src, dsts, keys=nil, value=nil
            @src = src
            @dsts = dsts
            @keys = keys
            @value = value
            @door = nil         # pointer to the source set from @src by Room#add_link
        end
        #
        # called by JSON#generate to serialize the Link object into JSON data
        #
        # @param [Array] a belongs to JSON generator
        #
        def to_json *a
            {
                'kls'       => self.class.name,
                'src'       => @src,
                'dsts'      => @dsts,
                'keys'      => @keys,
                'value'     => @value
            }.to_json *a
        end
        #
        # creates a Link object from a JSON data
        #
        # @param [Hash] o belongs to JSON parser
        #
        def self.json_create o
            raise Edoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            self.new o['src'], o['dsts'], o['keys'], o['value']
        end
        #
        # creates a Link object from the data of a particle
        #
        # @param [Particle] p the Particle to get Link attributes from
        #
        def self.from_particle p
            pl = p.payload
            Edoors::Link.new pl[Edoors::LNK_SRC], pl[Edoors::LNK_DSTS], pl[Edoors::LNK_KEYS], pl[Edoors::LNK_VALUE]
        end
        #
        attr_accessor :door
        attr_reader :src, :dsts, :keys, :value
        #
    end
    #
end
#
# EOF
