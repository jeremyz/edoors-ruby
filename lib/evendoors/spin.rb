#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Spin < Room
        #
        @pool = {}          # per particle class free list
        @sys_fifo = []      # system particles fifo list
        @app_fifo = []      # application particles fifo list
        #
        @spin = nil
        @run = false
        @debug_routing = false
        @debug_errors = false
        #
        class << self
            #
            attr_accessor :spin, :run, :debug_routing, :debug_errors
            #
            def to_json *a
                {
                    'sys_fifo'      => @sys_fifo,
                    'app_fifo'      => @app_fifo,
                    'debug_routing' => @debug_routing,
                    'debug_errors'  => @debug_errors
                }.to_json(*a)
            end
            #
            def static_json_create o
                @debug_routing = o['debug_routing']
                @debug_errors = o['debug_errors']
                o['app_fifo'].each do |particle|
                    @app_fifo << EvenDoors::Particle.json_create(particle)
                end
                o['sys_fifo'].each do |particle|
                    @sys_fifo <<  EvenDoors::Particle.json_create(particle)
                end
            end
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
            def spin!
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
            end
            #
            def clear!
                @spin= nil
                @pool.clear
                @sys_fifo.clear
                @app_fifo.clear
            end
            #
        end
        #
        def initialize n, args={}
            super n, nil
            raise EvenDoors::Exception.new "do not try to initialize more than one spin" if not self.class.spin.nil?
            self.class.spin = self
            self.class.debug_errors = args[:debug_errors] || false
            self.class.debug_routing = args[:debug_routing] || false
        end
        #
        def to_json *a
            {
                'kls'   => self.class.name,
                'name'  => @name,
                'spots' => @spots,
                'static' => EvenDoors::Spin
            }.to_json(*a)
        end
        #
        def self.json_create o
            raise EvenDoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            spin = self.new(o['name'])
            o['spots'].each do |name,spot|
                spin.add_spot EvenDoors::Room.json_create spot
            end
            EvenDoors::Spin.static_json_create o['static']
            spin
        end
        #
        def spin!
            @spots.values.each do |spot| spot.start! end
            self.class.run = true
            self.class.spin!
            @spots.values.each do |spot| spot.stop! end
        end
        #
    end
    #
end
#
# EOF
