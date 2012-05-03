#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'evendoors'

#
class InputDoor < EvenDoors::Door
    def start!
        puts " * start #{self.class.name} #{@path}" if EvenDoors::Twirl.debug
        @lines = [ "#{name} says : hello", "world ( from #{path} )" ]
        p = require_p EvenDoors::Particle
        p.set_dst EvenDoors::ACT_GET, path
        send_p p
    end
    # def stop!
    #     puts " * stop #{self.class.name} #{@path}" if EvenDoors::Twirl.debug
    # end
    def receive p
        puts " * #{self.class.name} receive_p : #{p.action}" if EvenDoors::Twirl.debug
        if p.action==EvenDoors::ACT_GET
            p.reset!
            p.set_data 'line', @lines.shift
            p.set_data 'f0', 'v0'
            p.set_data 'f1', 'v1'
            p.set_data 'f2', 'v2'
            send_p p
            if @lines.length>0
                p = require_p EvenDoors::Particle
                p.set_dst EvenDoors::ACT_GET, name
                send_p p
            end
        else
            # we can release it or let the Door do it
            release_p p
        end
    end
end
#
class OutputDoor < EvenDoors::Door
    # def start!
    #     puts " * start #{self.class.name} #{@path}" if EvenDoors::Twirl.debug
    # end
    # def stop!
    #     puts " * stop #{self.class.name} #{@path}" if EvenDoors::Twirl.debug
    # end
    def receive p
        if EvenDoors::Twirl.debug
            puts " * #{self.class.name} receive_p : #{@path} : DATA #{p.get_data('line')}"
        else
            puts p.get_data 'line'
        end
        # we do nothing EvenDoors::Twirl.process will detect it and release it
    end
end
#
space = EvenDoors::Space.new 'space', :debug=>false
room0 = EvenDoors::Room.new 'room0', space
room1 = space.add_spot EvenDoors::Room.new 'room1'
input0 = room0.add_spot InputDoor.new 'input0'
output0 = room0.add_spot OutputDoor.new 'output0'
input1 = room1.add_spot InputDoor.new 'input1'
output1 = room1.add_spot OutputDoor.new 'output1'
#
room0.add_link EvenDoors::Link.new('input0', 'output0', nil, nil, nil)
#
p0 = EvenDoors::Twirl.require_p EvenDoors::Particle
p0.set_data EvenDoors::LNK_SRC, 'input1'
p0.set_data EvenDoors::LNK_DSTS, 'output1'
p0.set_data EvenDoors::LNK_FIELDS, 'fx,fy,fz'
p0.set_data EvenDoors::LNK_CONDF, 'f0,f1,f2'
p0.set_data EvenDoors::LNK_CONDV, 'v0v1v2'
p0.set_dst EvenDoors::ACT_ADD_LINK, room1.path
room0.send_sys_p p0 # send_sys_p -> room0 -> space -> room1 -> input1
#
space.twirl!
#
#
# EOF
