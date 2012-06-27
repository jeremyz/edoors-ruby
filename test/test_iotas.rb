#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'edoors'

HBN_PATH='hibernate.json'
#
class InputDoor < Edoors::Door
    #
    @count = 0
    #
    class << self
        attr_accessor :count
    end
    #
    def initialize n, p
        super n, p
        @lines = [ "#{name} says : hello", "world ( from #{path} )" ]
        @idx = 0
    end
    #
    def start!
        puts " -> start #{self.class.name} (#{@path})"
        # stimulate myself
        p = require_p Edoors::Particle
        # p.add_dst Edoors::ACT_GET, path
        send_p p, Edoors::ACT_GET
    end
    #
    def stop!
        puts " >- stop  #{self.class.name} (#{@path})"
    end
    #
    def hibernate!
        puts " !! hibernate  #{self.class.name} (#{@path})"
        # we want to remember where we are in the data flow
        {'idx'=>@idx}
    end
    #
    def resume! o
        puts " !! resume  #{self.class.name} (#{@path})"
        # restore idx
        @idx = o['idx']
    end
    #
    def receive_p p
        puts " @ #{self.class.name} (#{@path}) receive_p : #{p.action}"
        if p.action==Edoors::ACT_GET
            p.reset!
            p.set_data 'line', @lines[@idx]
            p.set_data 'f0', 'v0'
            p.set_data 'f1', 'v1'
            p.set_data 'f2', 'v2'
            send_p p    # will follow the link
            @idx+=1
            if @idx<@lines.length
                # there is more to read, restimulate myself
                p = require_p Edoors::Particle
                p.add_dst Edoors::ACT_GET, name
                send_p p
            end
        else
            # we can release it or let the Door do it
            release_p p
        end
        # I want to hibernate now!
        self.class.count+=1
        if self.class.count==3
            p = require_p Edoors::Particle
            p[Edoors::FIELD_HIBERNATE_PATH] = HBN_PATH
            p.add_dst Edoors::SYS_ACT_HIBERNATE
            send_sys_p p
        end
    end
    #
end
#
class ConcatBoard < Edoors::Board
    #
    def initialize n, p, m=false
        super n, p
        @manual = m
    end
    #
    def start!
        puts " -> start #{self.class.name} (#{@path})"
    end
    #
    def stop!
        puts " >- stop  #{self.class.name} (#{@path})"
    end
    #
    def receive_p p
        puts " @ #{self.class.name} receive_p : #{p.action}"
        if p.action==Edoors::ACT_ERROR
            #
        else
            if @manual
                # cleanup unnecessary p2 Particle
                p2 = p.merged_shift
                p.set_data 'line', (p.data('line')+' '+p2.data('line'))
                release_p p2
            else
                # Or let the system do it
                p.set_data 'line', (p.data('line')+' '+p.merged(0).data('line'))
            end
            send_p p
        end
    end
    #
end
#
class OutputDoor < Edoors::Door
    #
    def initialize n, p, c=false
        super n, p
        @clean = c
    end
    #
    def start!
        puts " -> start #{self.class.name} (#{@path})"
    end
    #
    def stop!
        puts " >- stop  #{self.class.name} (#{@path})"
    end
    #
    def receive_p p
        puts " #==> #{self.class.name} (#{@path}) receive_p : #{p.get_data('line')}"
        if @clean
            release_p p
        else
            # we do nothing Edoors::Door#process_p will detect it and release it
        end
    end
    #
end
#
spin = Edoors::Spin.new 'dom0', :debug_routing=>false, :debug_garbage=>true
#
room0 = Edoors::Room.new 'room0', spin
room1 = Edoors::Room.new 'room1', spin
#
input0 = InputDoor.new 'input0', room0
output0 = OutputDoor.new 'output0', room0
#
input1 = InputDoor.new 'input1', room1
output1 = OutputDoor.new 'output1', room1, true
concat1 = ConcatBoard.new 'concat1', room1
#
room0.add_link Edoors::Link.new('input0', 'output0', nil, nil)
#
p0 = spin.require_p Edoors::Particle
p0.set_data Edoors::LNK_SRC, 'input1'
p0.set_data Edoors::LNK_DSTS, ['concat1?follow','output1']
p0.set_data Edoors::LNK_KEYS, ['f0','f2']
p0.set_data Edoors::LNK_VALUE, {'f0'=>'v0','f1'=>'v1','f2'=>'v2'}
p0.add_dst Edoors::SYS_ACT_ADD_LINK, room1.path
room1.send_sys_p p0 # send_sys_p -> room0 -> spin -> room1 -> input1
#
spin.spin!
#
dom0 = Edoors::Spin.resume! HBN_PATH
dom0.spin!
File.unlink HBN_PATH if File.exists? HBN_PATH
#
# EOF
