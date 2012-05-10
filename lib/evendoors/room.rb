#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Room < Spot
        #
        def initialize n, p=nil
            super n, p
            @spots = {}
            @links = {}
            @parent.add_spot self if @parent
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
            room = self.new o['name']
            o['spots'].each do |name,spot|
                room.add_spot eval( spot['kls'] ).json_create(spot)
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
            puts " * start #{path}" if EvenDoors::Spin.debug_routing
            @spots.values.each do |spot| spot.start! if spot.respond_to? :start! end
        end
        #
        def stop!
            puts " * stop #{path}" if EvenDoors::Spin.debug_routing
            @spots.values.each do |spot| spot.stop! if spot.respond_to? :stop! end
        end
        #
        def spin
            return @spin if @spin
            @spin = ( @parent.nil? ? self : @parent.spin )
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
            puts "   -> try_links ..." if EvenDoors::Spin.debug_routing
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
                        p2 = EvenDoors::Spin.require_p p.class
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
            elsif (p.room=~/^#{path}/)==0
                # TODO allow drill down ?!?
                p.error! EvenDoors::ERROR_ROUTE_RRNDD
            elsif @parent
                @parent.route_p p
            else
                p.error! EvenDoors::ERROR_ROUTE_TRWR
            end
        end
        #
        def send_p p
            puts " * send_p #{(p.next_dst.nil? ? 'no dst' : p.next_dst)} ..." if EvenDoors::Spin.debug_routing
            if p.src.nil?
                # do not route orphan particles !!
                p.error! EvenDoors::ERROR_ROUTE_NS, spin
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
            puts "   -> #{p.dst.path}#{EvenDoors::ACT_SEP}#{p.action}" if EvenDoors::Spin.debug_routing
            EvenDoors::Spin.send_p p
        end
        #
        def send_sys_p p
            puts " * send_sys_p #{(p.next_dst.nil? ? 'no dst' : p.next_dst)} ..." if EvenDoors::Spin.debug_routing
            if p.next_dst
                p.split_dst!
                if p.door
                    route_p p
                elsif p.action
                    p.dst_routed! spin
                end
            else
                p.error! EvenDoors::ERROR_ROUTE_SND
            end
            puts "   -> #{p.dst.path}#{EvenDoors::ACT_SEP}#{p.action}" if EvenDoors::Spin.debug_routing
            EvenDoors::Spin.send_sys_p p
        end
        #
        def process_sys_p p
            if p.action==EvenDoors::SYS_ACT_ADD_LINK
                add_link EvenDoors::Link.from_particle_data p
            end
            EvenDoors::Spin.release_p p
        end
        #
    end
    #
end
#
# EOF
