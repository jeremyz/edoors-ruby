#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Twirl
        #
        @debug = false
        @pool = {}          # per particle class free list
        @sys_fifo = []      # system particles fifo list
        @app_fifo = []      # application particles fifo list
        #
        #
        class << self
            #
            attr_accessor :debug
            #
            def release_p p
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
            def twirl!
                while @sys_fifo.length>0 or @app_fifo.length>0
                    while @sys_fifo.length>0
                        p = @sys_fifo.shift
                        p.door.process_sys_p p
                    end
                    while @app_fifo.length>0
                        p = @app_fifo.shift
                        p.door.process_p p
                    end
                end
            end
            #
        end
        #
    end
    #
end
#
# EOF
