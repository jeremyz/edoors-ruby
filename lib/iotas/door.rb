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
    class Door < Iota
        #
        def initialize n, p
            super n, p
            @saved = nil
        end
        #
        def to_json *a
            {
                'kls'   => self.class.name,
                'name'  => @name
            }.merge(hibernate!).to_json *a
        end
        #
        def self.json_create o
            raise Iotas::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            door = self.new o['name'], o['parent']
            door.resume! o
            door
        end
        #
        def require_p p_kls
            p = @spin.require_p p_kls
            p.src = self
            p
        end
        #
        def release_p p
            @saved=nil if @saved==p     # particle is released, all is good
            @spin.release_p p
        end
        #
        def garbage
            puts " ! #{path} didn't give back #{@saved}" if @spin.debug_errors
            puts "\t#{@saved.data Iotas::FIELD_ERROR_MSG}" if @saved.action==Iotas::ACT_ERROR
            release_p @saved
            @saved = nil
        end
        #
        def process_p p
            @viewer.receive_p p if @viewer
            @saved = p
            receive_p p
            garbage if not @saved.nil?
        end
        #
        def process_sys_p p
            # nothing todo with it now
            @spin.release_p p
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
