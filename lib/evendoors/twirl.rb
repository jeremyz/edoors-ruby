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
        @run = false
        #
        class << self
            #
            attr_accessor :debug, :run
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
            def twirl!
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
        end
        #
    end
    #
end
#
# EOF
