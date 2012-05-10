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
        @run = false
        @debug_routing = false
        @debug_errors = false
        #
        class << self
            #
            attr_accessor :run, :debug_routing, :debug_errors
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
                @sys_fifo.clear
                @app_fifo.clear
            end
            #
        end
        #
        def initialize n, args={}
            super n, nil
            self.class.debug_errors = args[:debug_errors] || false
            self.class.debug_routing = args[:debug_routing] || false
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
