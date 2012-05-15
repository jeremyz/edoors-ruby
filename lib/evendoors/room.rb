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
    class Room < Spot
        #
        def initialize n, p
            super n, p
            @spots = {}
            @links = {}
        end
        #
        def to_json *a
            {
                'kls'   => self.class.name,
                'name'  => @name,
                'spots' => @spots,
                'links' => @links
            }.to_json *a
        end
        #
        def self.json_create o
            raise EvenDoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            room = self.new o['name'], o['parent']
            o['spots'].each do |name,spot|
                eval( spot['kls'] ).json_create(spot.merge!('parent'=>room))
            end
            o['links'].each do |src,links|
                links.each do |link|
                    room.add_link EvenDoors::Link.json_create(link)
                end
            end
            room
        end
        #
        def add_spot s
            raise EvenDoors::Exception.new "Spot #{s.name} already has #{s.parent.name} as parent" if not s.parent.nil? and s.parent!=self
            raise EvenDoors::Exception.new "Spot #{s.name} already exists in #{path}" if @spots.has_key? s.name
            s.parent = self if s.parent.nil?
            @spots[s.name]=s
        end
        #
        def add_link l
            l.door = @spots[l.src]
            raise EvenDoors::Exception.new "Link source #{l.src} does not exist in #{path}" if l.door.nil?
            (@links[l.src] ||= [])<< l
        end
        #
        def start!
            puts " * start #{path}" if @spin.debug_routing
            @spots.values.each do |spot| spot.start! end
        end
        #
        def stop!
            puts " * stop #{path}" if @spin.debug_routing
            @spots.values.each do |spot| spot.stop! end
        end
        #
        def search_down spath
            return self if spath==path
            return nil if (spath=~/^#{path}\/(\w+)\/?/)!=0
            if spot = @spots[$1]
                return spot if spot.path==spath    # needed as Door doesn't implement #search_down
                return spot.search_down spath
            end
            nil
        end
        #
        def try_links p
            puts "   -> try_links ..." if @spin.debug_routing
            links = @links[p.src.name]
            return false if links.nil?
            pending_link = nil
            apply_link = false
            links.each do |link|
                apply_link = link.cond_fields.nil?  # unconditional link
                p.set_link_fields link.cond_fields if not apply_link
                if apply_link or (p.link_value==link.cond_value)
                    # link matches !
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
                send_p p
            end
            (not pending_link.nil?)
        end
        #
        def route_p p
            if p.room.nil? or p.room==path
                if door = @spots[p.door]
                    p.dst_routed! door
                else
                    p.error! EvenDoors::ERROR_ROUTE_RRWD
                end
            elsif (p.room=~/^#{path}\/(.*)/)==0
                room, *more = $1.split EvenDoors::PATH_SEP
                if child=@spots[room]
                    child.route_p p
                else
                    p.error! EvenDoors::ERROR_ROUTE_DDWR
                end
            elsif @parent
                @parent.route_p p
            else
                p.error! EvenDoors::ERROR_ROUTE_TRWR
            end
        end
        #
        def send_p p
            puts " * send_p #{(p.next_dst.nil? ? 'no dst' : p.next_dst)} ..." if @spin.debug_routing
            if p.src.nil?
                # do not route orphan particles !!
                p.error! EvenDoors::ERROR_ROUTE_NS, @spin
            elsif p.next_dst
                p.split_dst!
                if p.door
                    route_p p
                else
                    # boomerang
                    p.dst_routed! p.src
                end
            elsif try_links p
                return
            else
                p.error! EvenDoors::ERROR_ROUTE_NDNL
            end
            puts "   -> #{p.dst.path}#{EvenDoors::ACT_SEP}#{p.action}" if @spin.debug_routing
            @spin.post_p p
        end
        #
        def send_sys_p p
            puts " * send_sys_p #{(p.next_dst.nil? ? 'no dst' : p.next_dst)} ..." if @spin.debug_routing
            if p.next_dst
                p.split_dst!
                if p.door
                    route_p p
                elsif p.action
                    p.dst_routed! @spin
                end
            else
                p.error! EvenDoors::ERROR_ROUTE_SND
            end
            puts "   -> #{p.dst.path}#{EvenDoors::ACT_SEP}#{p.action}" if @spin.debug_routing
            @spin.post_sys_p p
        end
        #
        def process_sys_p p
            if p.action==EvenDoors::SYS_ACT_ADD_LINK
                add_link EvenDoors::Link.from_particle_data p
            end
            @spin.release_p p
        end
        #
    end
    #
end
#
# EOF
