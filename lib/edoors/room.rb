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
    ERROR_ROUTE_NS      = 'routing error: no source'.freeze
    ERROR_ROUTE_RRWD    = 'routing error: right room, wrong door'.freeze
    ERROR_ROUTE_DNE     = 'routing error: does not exists'.freeze
    ERROR_ROUTE_NDNL    = 'routing error: no destination, no link'.freeze
    ERROR_ROUTE_SND     = 'routing error: system no destination'.freeze
    #
    class Room < Iota
        #
        # creates a Room object from the arguments.
        #
        # @param [String] n the name of this Room
        # @param [Iota] p the parent
        #
        def initialize n, p
            super n, p
            @iotas = {}
            @links = {}
        end
        #
        # called by JSON#generate to serialize the Room object into JSON data
        #
        # @param [Array] a belongs to JSON generator
        #
        def to_json *a
            {
                'kls'   => self.class.name,
                'name'  => @name,
                'iotas' => @iotas,
                'links' => @links
            }.to_json *a
        end
        #
        # creates a Room object from a JSON data
        #
        # @param [Hash] o belongs to JSON parser
        #
        # @raise Edoors::Exception if the json kls attribute is wrong
        #
        def self.json_create o
            raise Edoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            room = self.new o['name'], o['parent']
            o['iotas'].each do |name,iota|
                eval( iota['kls'] ).json_create(iota.merge!('parent'=>room))
            end
            o['links'].each do |src,links|
                links.each do |link|
                    room.add_link Edoors::Link.json_create(link)
                end
            end
            room
        end
        #
        # creates a Room object from the data of a particle
        #
        # @param [Particle] p the Particle to get Room attributes from
        #
        def self.from_particle p, s
            Edoors::Room.new(p.get_data(Edoors::IOTA_NAME), s)
        end
        #
        # adds the given Iota to this Room
        #
        # @param [Iota] i the Iota to add
        #
        # @raise Edoors::Exception if i already has a parent or if a Iota with the same name already exists
        #
        def add_iota i
            raise Edoors::Exception.new "Iota #{i.name} already has #{i.parent.name} as parent" if not i.parent.nil? and i.parent!=self
            raise Edoors::Exception.new "Iota #{i.name} already exists in #{path}" if @iotas.has_key? i.name
            i.parent = self if i.parent.nil?
            @iotas[i.name]=i
        end
        #
        # adds the given Link to this Room
        #
        # @param [Link] l the Link to add
        #
        # @raise Edoors::Exception if the link source can't be found in this Room
        #
        def add_link l
            l.door = @iotas[l.src]
            raise Edoors::Exception.new "Link source #{l.src} does not exist in #{path}" if l.door.nil?
            (@links[l.src] ||= [])<< l
        end
        #
        # forward the call to each children
        #
        # @see Spin#spin! called on system bootup
        #
        def start!
            puts " * start #{path}" if @spin.debug_routing
            @iotas.values.each do |iota| iota.start! end
        end
        #
        # forward the call to each children
        #
        # @see Spin#spin! called on system shutdown
        #
        def stop!
            puts " * stop #{path}" if @spin.debug_routing
            @iotas.values.each do |iota| iota.stop! end
        end
        #
        # search through all children for a matching Iota
        #
        # @param [String] spath the full path of the earch Iota
        #
        # @return [Iota] if found
        #
        # @see Particle#initialize used to transform @src and @dst JSON data into refrences
        #
        def search_down spath
            return self if spath==path
            return nil if (spath=~/^#{path}\/(\w+)\/?/)!=0
            if iota = @iotas[$1]
                return iota if iota.path==spath    # needed as Door doesn't implement #search_down
                return iota.search_down spath
            end
            nil
        end
        #
        # search for a matching link
        #
        # @param [Particle] p the Particle searching for a matching link
        #
        def _try_links p
            puts "   -> try_links ..." if @spin.debug_routing
            links = @links[p.src.name]
            return false if links.nil?
            pending_link = nil
            links.each do |link|
                if p.link_with? link
                    if pending_link
                        p2 = @spin.require_p p.class
                        p2.clone_data p
                        p2.apply_link! link
                        send_p p2
                    end
                    pending_link = link
                end
            end
            if pending_link
                p.apply_link! pending_link
                _send p
            end
            pending_link
        end
        private :_try_links
        #
        # route the given Particle
        #
        # @param [Particle] p the Particle to be routed
        #
        def _route p
            if p.room.nil? or p.room==path
                if door = @iotas[p.door]
                    p.dst_routed! door
                else
                    p.error! Edoors::ERROR_ROUTE_RRWD
                end
            elsif door = @spin.search_world(p.room+Edoors::PATH_SEP+p.door)
                p.dst_routed! door
            else
                p.error! Edoors::ERROR_ROUTE_DNE
            end
        end
        private :_route
        #
        # send the given Particle
        #
        # @param [Particle] p the Particle to send
        # @param [Boolean] sys if true send to system Particle fifo
        #
        def _send p, sys=false
            if not sys and p.src.nil?
                # do not route non system orphan particles !!
                p.error! Edoors::ERROR_ROUTE_NS, @spin
            elsif p.dst
                # direct routing through pointer
                return
            elsif p.door
                # direct routing through path
                _route p
            elsif p.next_dst
                p.split_dst!
                if p.door
                    _route p
                elsif not sys
                    # boomerang
                    p.dst_routed! p.src
                elsif p.action
                    p.dst_routed! @spin
                end
            elsif not sys and _try_links p
                return
            else
                p.error!( sys ? Edoors::ERROR_ROUTE_SND : Edoors::ERROR_ROUTE_NDNL)
            end
        end
        private :_send
        #
        # send the given Particle to application Particle fifo
        #
        # @param [Particle] p the Particle to send
        #
        def send_p p
            puts " * send_p #{(p.next_dst.nil? ? 'no dst' : p.next_dst)} ..." if @spin.debug_routing
            _send p
            puts "   -> #{p.dst.path}#{Edoors::ACT_SEP}#{p.action}" if @spin.debug_routing
            @spin.post_p p
        end
        #
        # send the given Particle to system Particle fifo
        #
        # @param [Particle] p the Particle to send
        #
        def send_sys_p p
            puts " * send_sys_p #{(p.next_dst.nil? ? 'no dst' : p.next_dst)} ..." if @spin.debug_routing
            _send p, true
            puts "   -> #{p.dst.path}#{Edoors::ACT_SEP}#{p.action}" if @spin.debug_routing
            @spin.post_sys_p p
        end
        #
        # process the given system Particle
        #
        # @param [Particle] p the Particle to be processed
        #
        # @note the Particle is automatically released
        #
        def process_sys_p p
            if p.action==Edoors::SYS_ACT_ADD_LINK
                add_link Edoors::Link.from_particle p
            elsif p.action==Edoors::SYS_ACT_ADD_ROOM
                Edoors::Room.from_particle p, self
            end
            @spin.release_p p
        end
        #
    end
    #
end
#
# EOF
