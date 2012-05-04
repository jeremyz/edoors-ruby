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
            @cache = {}
            @parent.add_spot self if @parent
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
            puts " * start #{path}" if EvenDoors::Twirl.debug
            @spots.values.each do |spot| spot.start! if spot.respond_to? :start! end
        end
        #
        def stop!
            puts " * stop #{path}" if EvenDoors::Twirl.debug
            @spots.values.each do |spot| spot.stop! if spot.respond_to? :stop! end
        end
        #
        def try_links p
            pending_link = nil
            apply_link = false
            links = @links[p.src.name]
            return false if links.nil?
            links.each do |link|
                apply_link = link.cond_fields.nil?  # unconditional link
                p.set_link_fields link.cond_fields if not apply_link
                if apply_link or (p.link_value==link.cond_value)
                    # link matches !
                    if not pending_link.nil?
                        p2 = require_p p.class
                        p2.clone_data p
                        p2.src = link.door
                        p2.clear_dsts!
                        p2.add_dsts link.dsts
                        p2.set_link_fields link.fields
                        send_p p2
                    end
                    pending_link = link
                end
            end
            if pending_link
                p.src = pending_link.door
                p.clear_dsts!
                p.add_dsts pending_link.dsts
                p.set_link_fields pending_link.fields
                send_p p
            end
            (not pending_link.nil?)
        end
        #
        def route_p p, door_name
            if p.room.nil? or p.room==path
                if door = @spots[door_name]
                    p.dst_done! door
                else
                    p.error! EvenDoors::ERROR_ROUTE_RRWD
                end
            elsif @parent
                @parent.route_p p, door_name
            else
                p.error! EvenDoors::ERROR_ROUTE_TRWR
            end
        end
        #
        def send_p p
            if d = p.dst
                puts " * send #{d.to_str} ..." if EvenDoors::Twirl.debug
                route_p p, p.split_dst!
                puts "  -> #{p.door.path}:#{p.action}" if EvenDoors::Twirl.debug
                EvenDoors::Twirl.send_p p
            elsif not try_links p
                p.error! EvenDoors::ERROR_ROUTE_NDNL
                puts "  -> #{p.door.path}:#{p.action}" if EvenDoors::Twirl.debug
                EvenDoors::Twirl.send_p p
            end
        end
        #
        def send_sys_p p
            if d = p.dst
                puts " * send_sys #{d.to_str} ..." if EvenDoors::Twirl.debug
                route_p p, p.split_dst!
                puts "  -> #{p.door.path}:#{p.action}" if EvenDoors::Twirl.debug
                EvenDoors::Twirl.send_sys_p p
            else
                p.error! EvenDoors::ERROR_ROUTE_SND
                puts "  -> #{p.door.path}:#{p.action}" if EvenDoors::Twirl.debug
                EvenDoors::Twirl.send_sys_p p
            end
        end
        #
        def process_sys p
            if p.action==SYS_ACT_ADD_LINK
                add_link EvenDoors::Link.from_particle_data p
            end
            EvenDoors::Twirl.release_p p
        end
        #
    end
    #
end
#
# EOF
