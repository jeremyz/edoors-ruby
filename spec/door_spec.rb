#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe EvenDoors::Door do
    #
    before (:all) do
        @spin = EvenDoors::Spin.new 'dom0'
    end
    #
    before(:each) do
        @spin.clear!
    end
    #
    it "require_p release_p" do
        door = EvenDoors::Door.new 'hell', @spin
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
    it "NoMethodError when receive_p not overridden" do
        class Door0 < EvenDoors::Door
        end
        f = Fake.new 'fake', @spin
        d0 = Door0.new 'door0', f
        p0 = d0.require_p EvenDoors::Particle
        lambda { d0.process_p p0 }.should raise_error(NoMethodError)
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
        f = Fake.new 'fake', @spin
        d0 = Door0.new 'door0', f
        p0 = d0.require_p EvenDoors::Particle
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
        p1 = d0.require_p EvenDoors::Particle
        p1.should be p0
        #
        p0.set_dst! 'LOST'
        p0.split_dst!
        d0.process_p p0
        p1 = d0.require_p EvenDoors::Particle
        p1.should be p0
        #
        d0.process_sys_p p0
        p1 = @spin.require_p EvenDoors::Particle
        p1.should be p0
    end
    #
    it "door->json->door" do
        door = EvenDoors::Door.new 'hell', @spin
        hell = EvenDoors::Door.json_create( JSON.load( JSON.generate(door) ) )
        door.name.should eql hell.name
        JSON.generate(door).should eql JSON.generate(hell)
    end
    #
end
#
# EOF
