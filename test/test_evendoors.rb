#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'evendoors'

#
class InputDoor < EvenDoors::Door
    #
    def start!
        puts " * start #{self.class.name} #{@path}" if @spin.debug_routing
        @lines = [ "#{name} says : hello", "world ( from #{path} )" ]
        p = require_p EvenDoors::Particle
        p.set_dst! EvenDoors::ACT_GET, path
        send_p p
    end
    #
    # def stop!
    #     puts " * stop #{self.class.name} #{@path}" if @spin.debug_routing
    # end
    #
    def receive_p p
        puts " * #{self.class.name} receive_p : #{p.action}" if @spin.debug_routing
        if p.action==EvenDoors::ACT_GET
            p.reset!
            p.set_data 'line', @lines.shift
            p.set_data 'f0', 'v0'
            p.set_data 'f1', 'v1'
            p.set_data 'f2', 'v2'
            send_p p
            if @lines.length>0
                p = require_p EvenDoors::Particle
                p.set_dst! EvenDoors::ACT_GET, name
                send_p p
            end
        else
            # we can release it or let the Door do it
            release_p p
        end
    end
    #
end
#
class ConcatBoard < EvenDoors::Board
    #
    def receive_p p
        puts " * #{self.class.name} receive_p : #{p.action}" if @spin.debug_routing
        if p.action==EvenDoors::ACT_ERROR
            #
        else
            # MANUALLY
            # p2 = p.merged_shift
            # p.set_data 'line', (p.data('line')+' '+p2.data('line'))
            # release_p p2
            #
            # Or let the system do it
            p.set_data 'line', (p.data('line')+' '+p.merged(0).data('line'))
            send_p p
        end
    end
    #
end
#
class OutputDoor < EvenDoors::Door
    #
    # def start!
    #     puts " * start #{self.class.name} #{@path}" if @spin.debug_routing
    # end
    #
    # def stop!
    #     puts " * stop #{self.class.name} #{@path}" if @spin.debug_routing
    # end
    #
    def receive_p p
        if @spin.debug_routing
            puts " * #{self.class.name} receive_p : #{@path} : DATA #{p.get_data('line')}"
        else
            puts p.get_data 'line'
        end
        # we do nothing EvenDoors::Door#process_p will detect it and release it
    end
    #
end
#
spin = EvenDoors::Spin.new 'dom0', :debug_routing=>false, :debug_errors=>true
#
room0 = EvenDoors::Room.new 'room0', spin
room1 = EvenDoors::Room.new 'room1', spin
#
input0 = InputDoor.new 'input0', room0
output0 = OutputDoor.new 'output0', room0
#
input1 = InputDoor.new 'input1', room1
output1 = OutputDoor.new 'output1', room1
concat1 = ConcatBoard.new 'concat1', room1
#
room0.add_link EvenDoors::Link.new('input0', 'output0', nil, nil, nil)
#
p0 = spin.require_p EvenDoors::Particle
p0.set_data EvenDoors::LNK_SRC, 'input1'
p0.set_data EvenDoors::LNK_DSTS, 'concat1?follow,output1'
p0.set_data EvenDoors::LNK_FIELDS, 'f0,f2'
p0.set_data EvenDoors::LNK_CONDF, 'f0,f1,f2'
p0.set_data EvenDoors::LNK_CONDV, 'v0v1v2'
p0.set_dst! EvenDoors::SYS_ACT_ADD_LINK, room1.path
room1.send_sys_p p0 # send_sys_p -> room0 -> spin -> room1 -> input1
#
spin.spin!
#
#
# EOF
