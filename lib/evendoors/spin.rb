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
    class Spin < Room
        #
        def initialize n, o={}
            super n, nil
            #
            @pool = {}          # per particle class free list
            @sys_fifo = []      # system particles fifo list
            @app_fifo = []      # application particles fifo list
            #
            @run = false
            @hibernate_path = 'evendoors-hibernate-'+n+'.json'
            @debug_errors = o[:debug_errors]||o['debug_errors']||false
            @debug_routing = o[:debug_routing]||o['debug_routing']||false
            #
            if not o.empty?
                o['spots'].each do |name,spot|
                    EvenDoors::Room.json_create(spot.merge!('parent'=>self))
                end if o['spots']
                o['app_fifo'].each do |particle|
                    @app_fifo << EvenDoors::Particle.json_create(particle.merge!('spin'=>self))
                end if o['app_fifo']
                o['sys_fifo'].each do |particle|
                    @sys_fifo <<  EvenDoors::Particle.json_create(particle.merge!('spin'=>self))
                end if o['sys_fifo']
            end
        end
        #
        attr_accessor :run, :debug_errors, :debug_routing
        #
        def to_json *a
            {
                'kls'           => self.class.name,
                'timestamp'     => Time.now,
                'name'          => @name,
                'spots'         => @spots,
                'sys_fifo'      => @sys_fifo,
                'app_fifo'      => @app_fifo,
                'debug_errors'  => @debug_errors,
                'debug_routing' => @debug_routing
            }.to_json(*a)
        end
        #
        def self.json_create o
            raise EvenDoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            self.new o['name'], o
        end
        #
        def clear!
            @spots.clear
            @pool.clear
            @sys_fifo.clear
            @app_fifo.clear
        end
        #
        #
        def release_p p
            # hope there is no circular loop
            while p2=p.merged_shift
                release_p p2
            end
            ( @pool[p.class] ||= [] ) << p
        end
        #
        def require_p p_kls
            l = @pool[p_kls]
            return p_kls.new if l.nil?
            p = l.pop
            return p_kls.new if p.nil?
            p.reset!
            p
        end
        #
        def send_p p
            @app_fifo << p
        end
        #
        def send_sys_p p
            @sys_fifo << p
        end
        #
        def process_sys_p p
            if p.action==EvenDoors::SYS_ACT_HIBERNATE
                hibernate! p[FIELD_HIBERNATE_PATH]
            else
                super p
            end
        end
        #
        def spin!
            @spots.values.each do |spot| spot.start! end
            @run = true
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
            @spots.values.each do |spot| spot.stop! end
        end
        #
        def stop!
            @run=false
        end
        #
        def hibernate! path=nil
            stop!
            File.open(path||@hibernate_path,'w') do |f| f << JSON.pretty_generate(self) end
        end
        #
    end
    #
end
#
# EOF
