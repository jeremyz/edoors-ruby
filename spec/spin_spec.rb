#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe EvenDoors::Spin do
    #
    class MyP < EvenDoors::Particle; end
    #
    it "Particles pool" do
        spin = EvenDoors::Spin.new 'dom0'
        p0 = spin.require_p EvenDoors::Particle
        p1 = spin.require_p EvenDoors::Particle
        (p0===p1).should be_false
        spin.release_p p0
        p2 = spin.require_p EvenDoors::Particle
        (p0===p2).should be_true
    end
    #
    it "different Particles classes in pool" do
        spin = EvenDoors::Spin.new 'dom0'
        p0 = spin.require_p EvenDoors::Particle
        p1 = spin.require_p EvenDoors::Particle
        (p0===p1).should be_false
        spin.release_p p0
        p2 = spin.require_p MyP
        p3 = spin.require_p MyP
        (p2===p3).should be_false
        spin.release_p p2
        p4 = spin.require_p MyP
        (p2===p4).should be_true
    end
    #
    it "release of merged particles" do
        spin = EvenDoors::Spin.new 'dom0'
        p0 = spin.require_p EvenDoors::Particle
        p1 = spin.require_p EvenDoors::Particle
        (p0===p1).should be_false
        p0.merge! p1
        spin.release_p p0
        p2 = spin.require_p EvenDoors::Particle
        (p2===p0).should be_true
        p3 = spin.require_p EvenDoors::Particle
        (p3===p1).should be_true
    end
    #
    it "clear!" do
        spin = EvenDoors::Spin.new 'dom0'
        p0 = spin.require_p EvenDoors::Particle
        p1 = spin.require_p EvenDoors::Particle
        spin.send_p p0
        spin.release_p p1
        spin.clear!
        p2 = spin.require_p EvenDoors::Particle
        (p2==p0).should be_false
        (p2==p1).should be_false
    end
    #
    it "send_p send_sys_p spin!" do
        spin = EvenDoors::Spin.new 'dom0'
        f = Fake.new 'fake', spin
        p0 = spin.require_p EvenDoors::Particle
        p0.dst_routed!  f
        p1 = spin.require_p EvenDoors::Particle
        p1.dst_routed!  f
        spin.send_p p0
        spin.send_sys_p p1
        spin.run = true
        spin.spin!
        f.p.should be p0
        f.sp.should be p1
        spin.stop!
    end
    #
    it "option debug" do
        spin = EvenDoors::Spin.new 'dom0'
        spin.debug_routing.should be false
        spin.debug_errors.should be false
        spin = EvenDoors::Spin.new 'dom0', :debug_routing=>true, :debug_errors=>true
        spin.debug_routing.should be true
        spin.debug_errors.should be true
    end
    #
    it "spin->json->spin" do
        spin = EvenDoors::Spin.new 'dom0', :debug_routing=>true
        r0 = EvenDoors::Room.new 'r0', spin
        r1 = EvenDoors::Room.new 'r1', r0
        r2 = EvenDoors::Room.new 'r2', r1
        r3 = EvenDoors::Room.new 'r3', r1
        r4 = EvenDoors::Room.new 'r4', r3
        d0 = EvenDoors::Door.new 'd0', r1
        d1 = EvenDoors::Door.new 'd1', r1
        d2 = EvenDoors::Door.new 'd2', r2
        p0 = spin.require_p EvenDoors::Particle
        p1 = spin.require_p EvenDoors::Particle
        p2 = spin.require_p EvenDoors::Particle
        spin.send_p p0
        spin.send_p p1
        spin.send_sys_p p2
        json = JSON.generate spin
        dom0 = EvenDoors::Spin.json_create( JSON.load( json ) )
        json.should eql JSON.generate(dom0)
    end
    #
end
#
#EOF
