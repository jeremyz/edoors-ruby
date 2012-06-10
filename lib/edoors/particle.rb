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

require 'time'
#
module Edoors
    #
    class Particle
        #
        def initialize o={}
            @ts = Time.now      # creation time
            @src = nil          # Iota where it's originated from
            @dst = nil          # Iota where it's heading to
            @room = nil         # Room path part of the current destination
            @door = nil         # Door path part of the current destination
            @action = nil       # action part of the current destination
            @link_value = nil   # the value computed with the link_fields values extracted from the payload
                                # used for pearing Particles in Boards and linking in routing process
            @dsts = []          # fifo of path?action strings where to travel to
            @link_fields = []   # the fields used to generate the link value
            @payload = {}       # the actual data carried by this particle
            @merged = []        # list of merged particles
            #
            if not o.empty?
                @ts = Time.parse(o['ts']) if o['ts']
                @room = o['room']
                @door = o['door']
                @action = o['action']
                @payload = o['payload']||{}
                @src = o['spin'].search_down o['src'] if o['src']
                @dst = o['spin'].search_down o['dst'] if o['dst']
                o['dsts'].each do |dst| add_dsts dst end if o['dsts']
                set_link_fields *o['link_fields'] if o['link_fields']
                o['merged'].each do |particle|
                    merge! Particle.json_create(particle.merge!('spin'=>o['spin']))
                end if o['merged']
            end
        end
        #
        def to_json *a
            {
                'kls'           => self.class.name,
                'ts'            => @ts,
                'src'           => (@src ? @src.path : nil ),
                'dst'           => (@dst ? @dst.path : nil ),
                'room'          => @room,
                'door'          => @door,
                'action'        => @action,
                'dsts'          => @dsts,
                'link_fields'   => @link_fields,
                'payload'       => @payload,
                'merged'        => @merged
            }.to_json *a
        end
        #
        def self.json_create o
            raise Edoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            self.new o
        end
        #
        # called when released
        def reset!
            @ts = @src = @dst = @room = @door = @action = @link_value = nil
            @dsts.clear
            @link_fields.clear
            @payload.clear
            @merged.clear
        end
        #
        # called when sent
        def init! src
            @src = src
            @ts = Time.now
            @dst = @room = @door = @action = nil
        end
        #
        attr_reader :ts, :src, :dst, :room, :door, :action, :link_value, :payload
        #
        # routing
        #
        def next_dst
            @dsts[0]
        end
        #
        def clear_dsts!
            @dsts.clear
        end
        #
        def add_dsts dsts
            dsts.split(Edoors::LINK_SEP).each do |dst|
                if dst.empty? or dst[0]==Edoors::PATH_SEP or dst[0]==Edoors::PATH_SEP  or dst=~/\/\?/\
                    or dst=~/\/{2,}/ or dst=~/\s+/ or dst==Edoors::ACT_SEP
                    raise Edoors::Exception.new "destination #{dst} is not acceptable"
                end
                @dsts << dst
            end
        end
        #
        def add_dst a, d=''
            add_dsts d+Edoors::ACT_SEP+a
        end
        #
        def set_dst! a, d
            @action = a
            if d.is_a? Edoors::Iota
                @dst = d
            else
                _split_path! d
            end
        end
        #
        def split_dst!
            @dst = @room = @door = @action = nil
            return if (n = next_dst).nil?
            p, @action = n.split Edoors::ACT_SEP
            _split_path! p
        end
        #
        def _split_path! p
            i = p.rindex Edoors::PATH_SEP
            if i.nil?
                @room = nil
                @door = p
            else
                @room = p[0..i-1]
                @door = p[i+1..-1]
            end
            @door = nil if @door.empty?
        end
        private :_split_path!
        #
        def dst_routed! dst
            @dst = dst
            @dsts.shift
        end
        #
        def error! e, dst=nil
            @action = Edoors::ACT_ERROR
            @dst = dst||@src
            @payload[Edoors::FIELD_ERROR_MSG]=e
        end
        #
        def apply_link! lnk
            init! lnk.door
            clear_dsts!
            add_dsts lnk.dsts
            set_link_fields lnk.fields
        end
        #
        # data manipulation
        #
        def []=  k, v
            @payload[k]=v
            compute_link_value! if @link_fields.include? k
        end
        #
        def set_data k, v
            @payload[k] = v
            compute_link_value! if @link_fields.include? k
        end
        #
        def []  k
            @payload[k]
        end
        #
        def get_data k
            @payload[k]
        end
        alias :data :get_data
        #
        def clone_data p
            @payload = p.payload.clone
        end
        #
        # link value and fields
        #
        def set_link_fields *args
            @link_fields.clear if not @link_fields.empty?
            args.compact!
            args.each do |lfs|
                lfs.split(',').each do |lf|
                    @link_fields << lf
                end
            end
            compute_link_value!
        end
        #
        def compute_link_value!
            @link_value = @link_fields.inject('') { |s,lf| s+=@payload[lf].to_s if @payload[lf]; s }
        end
        #
        # merge particles management
        #
        def merge! p
            @merged << p
        end
        #
        def merged i
            @merged[i]
        end
        #
        def merged_shift
            @merged.shift
        end
        #
        def clear_merged!
            @merged.clear
        end
        #
    end
    #
end
#
# EOF
