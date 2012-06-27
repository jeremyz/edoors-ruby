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
        # creates a Particle object from the arguments.
        #
        # @param [Hash] o a customizable set of options
        #
        # @option o 'ts' [String]
        #   creation time
        # @option o 'src' [String]
        #   Iota where it's originated from
        # @option o 'dst' [String]
        #   Iota where it's heading to
        # @option o 'room' [String]
        #   Room path part of the current destination
        # @option o 'door' [String]
        #   Door path part of the current destination
        # @option o 'action' [String]
        #   action part of the current destination
        # @option o 'dsts' [String]
        #   fifo of path?action strings where to travel to
        # @option o 'link_keys' [String]
        #   unordered keys used has payload keys to build link_value
        # @option o 'payload' [String]
        #   the data carried by this particle
        # @option o 'merged' [String]
        #   list of merged particles
        #
        # @see Spin#require_p require a Particle
        #
        def initialize o={}
            @ts = Time.now      # creation time
            @src = nil          # Iota where it's originated from
            @dst = nil          # Iota where it's heading to
            @room = nil         # Room path part of the current destination
            @door = nil         # Door path part of the current destination
            @action = nil       # action part of the current destination
            @dsts = []          # fifo of path?action strings where to travel to
            @link_keys = []     # unordered keys used has payload keys to build link_value
            @link_value = {}    # the payload keys and values corresponding to the link keys
            @payload = {}       # the data carried by this particle
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
                add_dsts *o['dsts'] if o['dsts']
                set_link_keys *o['link_keys'] if o['link_keys']
                o['merged'].each do |particle|
                    merge! Particle.json_create(particle.merge!('spin'=>o['spin']))
                end if o['merged']
            end
        end
        #
        # called by JSON#generate to serialize the Particle object into JSON data
        #
        # @param [Array] a belongs to JSON generator
        #
        def to_json *a
            {
                'kls'       => self.class.name,
                'ts'        => @ts,
                'src'       => (@src ? @src.path : nil ),
                'dst'       => (@dst ? @dst.path : nil ),
                'room'      => @room,
                'door'      => @door,
                'action'    => @action,
                'dsts'      => @dsts,
                'link_keys' => @link_keys,
                'payload'   => @payload,
                'merged'    => @merged
            }.to_json *a
        end
        #
        # creates a Particle object from a JSON data
        #
        # @param [Hash] o belongs to JSON parser
        #
        # @raise Edoors::Exception if the json kls attribute is wrong
        #
        def self.json_create o
            raise Edoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            self.new o
        end
        #
        # clears all attributes
        #
        # @see Spin#release_p called whe na Particle is released
        #
        def reset!
            clear_merged! ( @src ? @src : ( @dst ? @dst : nil ) )
            @ts = @src = @dst = @room = @door = @action = nil
            @dsts.clear
            @link_value.clear
            @link_keys.clear
            @payload.clear
        end
        #
        # sets @src, @ts, and reset others
        #
        # @see Particle#apply_link! called when a Link is applied
        # @see Door#_send called when a Door sends a Particle
        #
        def init! src
            @src = src
            @ts = Time.now
            @dst = @room = @door = @action = nil
        end
        #
        attr_reader :ts, :src, :dst, :room, :door, :action, :payload, :link_value
        #
        # returns the next destination
        #
        def next_dst
            @dsts[0]
        end
        #
        # clears the destination list
        #
        def clear_dsts!
            @dsts.clear
        end
        #
        # adds destinations to the destination list
        #
        # @param [Array] dsts destinations to add
        #
        # @raise Edoors::Exception if a destination is not acceptable
        #
        # The parameters are checked before beeing added.
        # they must not be empty or be '?' or start with '/'
        # or contain '/?' or '//' or '\s+'
        #
        def add_dsts *dsts
            dsts.each do |dst|
                if dst.empty? or dst==Edoors::ACT_SEP or dst[0]==Edoors::PATH_SEP \
                    or dst=~/\/\?/ or dst=~/\/{2,}/ or dst=~/\s+/
                    raise Edoors::Exception.new "destination #{dst} is not acceptable"
                end
                @dsts << dst
            end
        end
        #
        # adds a destination to the destination list
        #
        # @param [String] a the action
        # @param [String] d the destination
        #
        def add_dst a, d=''
            add_dsts d+Edoors::ACT_SEP+a
        end
        #
        # sets the current destination
        #
        # @param [String] a the action
        # @param [String Iota] d the destination
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
        # splits the next destination into @room, @door, @action attributes
        #
        # the @dst attribute is set to nil
        # the @room, @door, @action attributes are set to nil if not defined
        #
        def split_dst!
            @dst = @room = @door = @action = nil
            return if (n = next_dst).nil?
            p, @action = n.split Edoors::ACT_SEP
            _split_path! p
        end
        #
        # called by Particle#split_dst! to split the path part of the destination
        #
        # @param [String] p path to be splitted
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
        # sets the current destination and shift the head of destination list
        #
        # @param [Iota] dst the current destination
        #
        # @see Room#_route routing success
        # @see Room#_send routing failure
        #
        def dst_routed! dst
            @dst = dst
            @dsts.shift
        end
        #
        # sets the error message, the destination and action
        #
        # @param [String] e error message
        # @param [Iota] dst the destination, @src if nil
        #
        # the error message is set into @payload[[Edoors::FIELD_ERROR_MSG]
        #
        def error! e, dst=nil
            @action = Edoors::ACT_ERROR
            @dst = dst||@src
            @payload[Edoors::FIELD_ERROR_MSG]=e
        end
        #
        # applies the effects of the given Link
        #
        # @param [Link] lnk the link to apply effects
        #
        # updates @src with Link @src, clears the destination list
        # adds the Link destinations to @dsts, sets the @link_keys
        #
        def apply_link! lnk
            init! lnk.door
            clear_dsts!
            add_dsts *lnk.dsts
            set_link_keys *lnk.keys
        end
        #
        # adds/updates a key value pair into payload
        #
        # @param [String] k the key
        # @param [Object] v the value
        #
        # \@link_value attribute will be updated if impacted
        #
        def []=  k, v
            @link_value[k] = v if @link_keys.include? k
            @payload[k] = v
        end
        alias :set_data :[]=
        #
        # destroys the value paired with a key
        #
        # @param [String] k the key
        #
        # @return the associated value
        #
        # \@link_value attribute will be updated if impacted
        #
        def del_data k
            @link_value.delete k if @link_keys.include? k
            @payload.delete k
        end
        #
        # retrieves a data value from a key
        #
        # @param [String] k the key
        #
        def [] k
            @payload[k]
        end
        #
        alias :get_data :[]
        alias :data :[]
        #
        # clones the payload of the given Particle
        #
        # @param [Particle] p the Particle to clone the payload of
        #
        def clone_data p
            @payload = p.payload.clone
        end
        #
        # sets the links keys
        #
        # @param [Array] args list of keys to set
        #
        # \@link_value attribute will be updated
        #
        def set_link_keys *args
            @link_keys.clear if not @link_keys.empty?
            args.compact!
            args.each do |lf|
                @link_keys << lf
            end
            @link_value = @payload.select { |k,v| @link_keys.include? k }
        end
        #
        # tries to link the Particle with the given Link
        #
        # @param [Link] link the link to try to link with
        #
        # returns true if the value of the Link is nil
        # otherwise checks if the extracted key values pairs from the Particle
        # payload using the Link value keys as selectors, equals the Link value
        #
        # @return [Boolean] true if the Link links with the Particle
        #
        def link_with? link
            return true if link.value.nil?
            link.value.keys.inject({}) { |h,k| h[k]=@payload[k] if @payload.has_key?(k); h }.eql? link.value
        end
        #
        # merges the given Particle in
        #
        # @param [Particle] p the Particle to merge in
        #
        def merge! p
            @merged << p
        end
        #
        # returns a merged Particle
        #
        # @param [Integer] i the index into the merged Particle list
        #
        def merged i
            @merged[i]
        end
        #
        # shifts the merged Particle list
        #
        def merged_shift
            @merged.shift
        end
        #
        # recursively clears the merged Particle list
        #
        # @param [Boolean] r releases the cleared Particle if true
        #
        def clear_merged! r=false
            @merged.each do |p|
                p.clear_merged! r
                r.release_p p if r
            end
            @merged.clear
        end
        #
    end
    #
end
#
# EOF
