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
        # creates a Door object from the arguments.
        #
        # @param [String] n the name of this Door
        # @param [Iota] p the parent
        #
        def initialize n, p
            super n, p
            @saved = nil
        end
        #
        # called by JSON#generate to serialize the Door object into JSON data
        #
        # @param [Array] a belongs to JSON generator
        #
        def to_json *a
            {
                'kls'   => self.class.name,
                'name'  => @name
            }.merge(hibernate!).to_json *a
        end
        #
        # creates a Door object from a JSON data
        #
        # @param [Hash] o belongs to JSON parser
        #
        # @raise Edoors::Exception if the json kls attribute is wrong
        #
        def self.json_create o
            raise Edoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            door = self.new o['name'], o['parent']
            door.resume! o
            door
        end
        #
        # require a Particle of the given class
        #
        # @param [Class] p_kls the class of the desired Particle
        #
        def require_p p_kls=Edoors::Particle
            @spin.require_p p_kls
        end
        #
        # release the given Particle
        #
        # @param [Particle] p the Particle to be released
        #
        def release_p p
            @saved=nil if @saved==p     # particle is released, all is good
            @spin.release_p p
        end
        #
        # release the Particle that have not been released or sent by user code
        #
        def _garbage
            puts " ! #{path} didn't give back #{@saved}" if @spin.debug_garbage
            puts "\t#{@saved.data Edoors::FIELD_ERROR_MSG}" if @saved.action==Edoors::ACT_ERROR
            @spin.release_p @saved
            @saved = nil
        end
        private :_garbage
        #
        # process the given particle then forward it to user code
        #
        # @param [Particle] p the Particle to be forwarded to user code
        #
        def process_p p
            @viewer.receive_p p if @viewer
            @saved = p
            receive_p p
            _garbage if not @saved.nil?
        end
        #
        # dead end, for now user defined Door do not have to deal with system Particle
        # the Particle is released
        #
        # @param [Particle] p the Particle to deal with
        #
        def process_sys_p p
            # nothing todo with it now
            @spin.release_p p
        end
        #
        # send the given Particle through the direct @parent
        #
        # @param [Particle] p the Particle to be sent
        # @param [Boolean] sys if true send to system Particle fifo
        # @param [String] a the post action
        # @param [Iota] d the post destination
        #
        def _send p, sys, a, d
            p.init! self
            p.set_dst! a, d||self if a
            @saved=nil if @saved==p # particle is sent back the data, all is good
            # daddy will know what to do
            sys ? @parent.send_sys_p(p) : @parent.send_p(p)
        end
        private :_send
        #
        # send the given Particle to the user fifo
        #
        # @param [Particle] p the Particle to be sent
        # @param [String] a the post action
        # @param [Iota] d the post destination
        #
        # @see Door#_send real implementation
        #
        def send_p p, a=nil, d=nil
            _send p, false, a, d
        end
        #
        # send the given Particle to the system fifo
        #
        # @param [Particle] p the Particle to be sent
        # @param [String] a the post action
        # @param [Iota] d the post destination
        #
        # @see Door#_send real implementation
        #
        def send_sys_p p, a=nil, d=nil
            _send p, true, a, d
        end
        #
    end
    #
end
#
# EOF
