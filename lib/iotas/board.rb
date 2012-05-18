#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# Copyright 2012 Jérémy Zurcher <jeremy@asynk.ch>
#
# This file is part of iotas.
#
# iotas is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iotas is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with iotas.  If not, see <http://www.gnu.org/licenses/>.

#
module Iotas
    #
    ACT_FOLLOW = 'follow'.freeze
    #
    class Board < Door
        #
        def initialize n, p
            super n, p
            @postponed = {}
        end
        #
        def to_json *a
            {
                'kls'       => self.class.name,
                'name'      => @name,
                'postponed' => @postponed
            }.merge(hibernate!).to_json *a
        end
        #
        def self.json_create o
            raise Iotas::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            board = self.new o['name'], o['parent']
            o['postponed'].each do |link_value,particle|
                board.process_p Iotas::Particle.json_create(particle.merge!('spin'=>board.spin))
            end
            board.resume! o
            board
        end
        #
        def process_p p
            @viewer.receive_p p if @viewer
            if p.action!=Iotas::ACT_ERROR
                p2 = @postponed[p.link_value] ||= p
                return if p2==p
                @postponed.delete p.link_value
                p,p2 = p2,p if p.action==Iotas::ACT_FOLLOW
                p.merge! p2
            end
            @saved = p
            receive_p p
            garbage if not @saved.nil?
        end
        #
    end
    #
end
#
# EOF