#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe EvenDoors::Door do
    #
    it "require_p release_p" do
        door = EvenDoors::Door.new 'hell'
        p0 = door.require_p EvenDoors::Particle
        p0.src.should be door
        p1 = door.require_p EvenDoors::Particle
        p1.src.should be door
        (p0===p1).should be_false
        door.release_p p0
        p2 = door.require_p EvenDoors::Particle
        p2.src.should be door
        (p0===p2).should be_true
    end
    #
    it "send_p, send_sys_p, release_p and release of lost particles" do
        class Door0 < EvenDoors::Door
            def receive_p p
                case p.action
                when 'RELEASE'
                    release_p p
                when 'SEND'
                    send_p p
                when 'SEND_SYS'
                    send_sys_p p
                else
                    # lost!!
                end
            end
        end
        f = Fake.new
        d0 = Door0.new 'door0', f
        p0 = EvenDoors::Spin.require_p EvenDoors::Particle
        #
        p0.set_dst! 'SEND'
        p0.split_dst!
        d0.process_p p0
        f.p.should eql p0
        #
        p0.set_dst! 'SEND_SYS'
        p0.split_dst!
        d0.process_p p0
        f.sp.should eql p0
        #
        p0.set_dst! 'RELEASE'
        p0.split_dst!
        d0.process_p p0
        p1 = EvenDoors::Spin.require_p EvenDoors::Particle
        p1.should be p0
        #
        p0.set_dst! 'LOST'
        p0.split_dst!
        d0.process_p p0
        p1 = EvenDoors::Spin.require_p EvenDoors::Particle
        p1.should be p0
        #
        d0.process_sys_p p0
        p1 = EvenDoors::Spin.require_p EvenDoors::Particle
        p1.should be p0
    end
    #
end
#
# EOF
