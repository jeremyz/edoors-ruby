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
    class Link
        #
        def initialize src, dsts, fields=nil, cond_fields=nil, cond_value=nil
            @src = src                      # link source name
            @dsts = dsts                    # , separated destinations to apply to the particle on linking success
            @fields = fields                # , separated fields to apply to the particle on linking success
            @cond_fields = cond_fields      # , separated fields used to generate the link value with particle payload
            @cond_value = cond_value        # value which will be compared to the particle link value to link or not
            @door = nil                     # pointer to the source
        end
        #
        def to_json *a
            {
                'kls'           => self.class.name,
                'src'           => @src,
                'dsts'          => @dsts,
                'fields'        => @fields,
                'cond_fields'   => @cond_fields,
                'cond_value'    => @cond_value
            }.to_json *a
        end
        #
        def self.json_create o
            raise EvenDoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            self.new o['src'], o['dsts'], o['fields'], o['cond_fields'], o['cond_value']
        end
        #
        def self.from_particle_data p
            EvenDoors::Link.new(p.get_data(EvenDoors::LNK_SRC), p.get_data(EvenDoors::LNK_DSTS),
                                p.get_data(EvenDoors::LNK_FIELDS), p.get_data(EvenDoors::LNK_CONDF),
                                p.get_data(EvenDoors::LNK_CONDV))
        end
        #
        attr_accessor :door
        attr_reader :src, :dsts, :fields, :cond_fields, :cond_value
        #
    end
    #
end
#
# EOF
