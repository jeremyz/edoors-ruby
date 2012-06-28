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
    class Spin < Room
        #
        # creates a Spin object from the arguments.
        #
        # @param [String] n the name of this Spin
        # @param [Hash] o a customizable set of options
        #
        # @option o 'debug_garbage' [String Symbol]
        #   output debug information about automatic garbage
        # @option o 'debug_routing' [String Symbol]
        #   output debug information about routing
        # @option o 'hibernation' [Boolean]
        #   if set to true Iota#start! won't be called within Spin#spin!
        # @option o 'inner_room' [Hash]
        #   composed of 2 keys, 'iotas' and 'links' use to repopulate the super class Room
        # @option o 'app_fifo' [Array]
        #   list of Particle to feed @app_fifo
        # @option o 'sys_fifo' [Array]
        #   list of Particle to feed @sys_fifo
        #
        #
        def initialize n, o={}
            super n, nil
            #
            @pool       = {}    # per particle class free list
            @world      = {}    # global iotas index
            @sys_fifo   = []    # system particles fifo list
            @app_fifo   = []    # application particles fifo list
            #
            @run = false
            @hibernation    = o['hibernation']||false
            @hibernate_path = 'edoors-hibernate-'+n+'.json'
            @debug_garbage  = o[:debug_garbage]||o['debug_garbage']||false
            @debug_routing  = o[:debug_routing]||o['debug_routing']||false
            #
            if not o.empty?
                room = o['inner_room']
                if room
                    room['iotas'].each do |name,iota|
                        eval( iota['kls'] ).json_create(iota.merge!('parent'=>self))
                    end
                    room['links'].each do |src,links|
                        links.each do |link|
                            add_link Edoors::Link.json_create(link)
                        end
                    end
                end
                o['app_fifo'].each do |particle|
                    @app_fifo << Edoors::Particle.json_create(particle.merge!('spin'=>self))
                end if o['app_fifo']
                o['sys_fifo'].each do |particle|
                    @sys_fifo <<  Edoors::Particle.json_create(particle.merge!('spin'=>self))
                end if o['sys_fifo']
            end
        end
        #
        attr_accessor :run, :hibernate_path, :debug_garbage, :debug_routing
        #
        # called by JSON#generate to serialize the Spin object into JSON data
        #
        # @param [Array] a belongs to JSON generator
        #
        def to_json *a
            {
                'kls'           => self.class.name,
                'timestamp'     => Time.now,
                'name'          => @name,
                'hibernation'   => @hibernation,
                'inner_room'    => { :iotas=>@iotas, :links=>@links },
                'sys_fifo'      => @sys_fifo,
                'app_fifo'      => @app_fifo,
                'debug_garbage' => @debug_garbage,
                'debug_routing' => @debug_routing
            }.to_json(*a)
        end
        #
        # creates a Spin object from a JSON data
        #
        # @param [Hash] o belongs to JSON parser
        #
        # @raise Edoors::Exception if the json kls attribute is wrong
        #
        def self.json_create o
            raise Edoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            self.new o['name'], o
        end
        #
        # add the given Iota to the global Hash
        #
        # @param [Iota] iota the Iota to register
        #
        # @see Room#_route @world hash is used for routing
        #
        def add_to_world iota
            @world[iota.path] = iota
        end
        #
        # search the global Hash for the matching Iota
        #
        # @param [String] path the path to the desired Iota
        #
        # @see Room#_route @world hash is used for routing
        #
        def search_world path
            @world[path]
        end
        #
        # clears all the structures
        #
        def clear!
            @links.clear
            @iotas.clear
            @world.clear
            @pool.clear
            @sys_fifo.clear
            @app_fifo.clear
        end
        #
        # releases the given Particle
        #
        # @parama [Particle] p the Particle to be released
        #
        # @note the Particle is stored into Hash @pool to be reused as soon as needed
        #
        # @see Particle#reset! the Particle is reseted before beeing stored
        #
        def release_p p
            # hope there is no circular loop
            while p2=p.merged_shift
                release_p p2
            end
            p.reset!
            ( @pool[p.class] ||= [] ) << p
        end
        #
        # requires a Particle of the given Class
        #
        # @param [Class] p_kls the desired Class of Particle
        #
        # @note if there is no Particle of the given Class, one is created
        #
        def require_p p_kls
            l = @pool[p_kls]
            return p_kls.new if l.nil?
            p = l.pop
            return p_kls.new if p.nil?
            p
        end
        #
        # add the given Particle to the application Particle fifo
        #
        # @param [Particle] p the Particle to add
        #
        def post_p p
            @app_fifo << p
        end
        #
        # add the given Particle to the system Particle fifo
        #
        # @param [Particle] p the Particle to add
        #
        def post_sys_p p
            @sys_fifo << p
        end
        #
        # process the given particle
        #
        # @param [Particle] p the Particle to be processed
        #
        def process_sys_p p
            if p.action==Edoors::SYS_ACT_HIBERNATE
                stop!
                hibernate! p[FIELD_HIBERNATE_PATH]
            else
                super p
            end
        end
        #
        # starts the system mainloop
        #
        # first Iota#start! is called on each children unless the system is resuming from hibernation
        # then while there is Particle in the fifo, first process all system Particle then 1 application Particle
        # after all Iota#stop! is called on each children, unless the system is going into hibernation
        #
        def spin!
            @iotas.values.each do |iota| iota.start! end unless @hibernation
            @run = true
            @hibernation = false
            while @run and (@sys_fifo.length>0 or @app_fifo.length>0)
                while @run and @sys_fifo.length>0
                    p = @sys_fifo.shift
                    p.dst.process_sys_p p
                end
                while @run and @app_fifo.length>0
                    p = @app_fifo.shift
                    p.dst.process_p p
                    break
                end
            end
            @iotas.values.each do |iota| iota.stop! end unless @hibernation
        end
        #
        # stops the spinning
        #
        def stop_spinning!
            @run=false
        end
        #
        # sends the system into hibernation
        #
        # @param [String] path the path to the hibernation file
        #
        # the system is serialized into JSON data and flushed to disk
        #
        def hibernate! path=nil
            @hibernation = true
            File.open(path||@hibernate_path,'w') do |f| f << JSON.pretty_generate(self) end
        end
        #
        # resumes the system from the given hibernation file
        #
        # @param [String] path the hibernation file to load the system from
        #
        def self.resume! path
            self.json_create JSON.load File.open(path,'r') { |f| f.read }
        end
        #
    end
    #
end
#
# EOF
