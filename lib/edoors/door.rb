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
            raise Edoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            door = self.new o['name'], o['parent']
            door.resume! o
            door
        end
        #
        def require_p p_kls
            @spin.require_p p_kls
        end
        #
        def release_p p
            @saved=nil if @saved==p     # particle is released, all is good
            @spin.release_p p
        end
        #
        def garbage
            puts " ! #{path} didn't give back #{@saved}" if @spin.debug_errors
            puts "\t#{@saved.data Edoors::FIELD_ERROR_MSG}" if @saved.action==Edoors::ACT_ERROR
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
        def _send sys, p, a=nil, d=nil
            p.init! self
            p.set_dst! a, d||self if a
            @saved=nil if @saved==p # particle is sent back the data, all is good
            # daddy will know what to do
            sys ? @parent.send_sys_p(p) : @parent.send_p(p)
        end
        private :_send
        #
        def send_p p, a=nil, d=nil
            _send false, p, a, d
        end
        #
        def send_sys_p p, a=nil, d=nil
            _send true, p, a, d
        end
        #
    end
    #
end
#
# EOF
