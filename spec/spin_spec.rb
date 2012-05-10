#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe EvenDoors::Spin do
    #
    before(:each) do
        EvenDoors::Spin.clear!
    end
    #
    class MyP < EvenDoors::Particle; end
    #
    it "Particles pool" do
        p0 = EvenDoors::Spin.require_p EvenDoors::Particle
        p1 = EvenDoors::Spin.require_p EvenDoors::Particle
        (p0===p1).should be_false
        EvenDoors::Spin.release_p p0
        p2 = EvenDoors::Spin.require_p EvenDoors::Particle
        (p0===p2).should be_true
    end
    #
    it "different Particles classes in pool" do
        p0 = EvenDoors::Spin.require_p EvenDoors::Particle
        p1 = EvenDoors::Spin.require_p EvenDoors::Particle
        (p0===p1).should be_false
        EvenDoors::Spin.release_p p0
        p2 = EvenDoors::Spin.require_p MyP
        p3 = EvenDoors::Spin.require_p MyP
        (p2===p3).should be_false
        EvenDoors::Spin.release_p p2
        p4 = EvenDoors::Spin.require_p MyP
        (p2===p4).should be_true
    end
    #
    it "release of merged particles" do
        p0 = EvenDoors::Spin.require_p EvenDoors::Particle
        p1 = EvenDoors::Spin.require_p EvenDoors::Particle
        (p0===p1).should be_false
        p0.merge! p1
        EvenDoors::Spin.release_p p0
        p2 = EvenDoors::Spin.require_p EvenDoors::Particle
        (p2===p0).should be_true
        p3 = EvenDoors::Spin.require_p EvenDoors::Particle
        (p3===p1).should be_true
    end
    #
    it "send_p send_sys_p spin!" do
        f = Fake.new
        p0 = EvenDoors::Spin.require_p EvenDoors::Particle
        p0.dst_routed!  f
        p1 = EvenDoors::Spin.require_p EvenDoors::Particle
        p1.dst_routed!  f
        EvenDoors::Spin.send_p p0
        EvenDoors::Spin.send_sys_p p1
        EvenDoors::Spin.run = true
        EvenDoors::Spin.spin!
        f.p.should be p0
        f.sp.should be p1
    end
    #
    it "option debug" do
        EvenDoors::Spin.debug_routing.should be false
        EvenDoors::Spin.debug_errors.should be false
        spin = EvenDoors::Spin.new 'dom0', :debug_routing=>true, :debug_errors=>true
        EvenDoors::Spin.debug_routing.should be true
        EvenDoors::Spin.debug_errors.should be true
    end
    #
    it "only 1 Spin instance" do
        spin = EvenDoors::Spin.new 'dom0', :debug_routing=>true
        lambda { EvenDoors::Spin.new('dom1') }.should raise_error(EvenDoors::Exception)
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
        p0 = EvenDoors::Spin.require_p EvenDoors::Particle
        p1 = EvenDoors::Spin.require_p EvenDoors::Particle
        p2 = EvenDoors::Spin.require_p EvenDoors::Particle
        EvenDoors::Spin.send_p p0
        EvenDoors::Spin.send_p p1
        EvenDoors::Spin.send_sys_p p2
        json = JSON.generate spin
        EvenDoors::Spin.clear!
        dom0 = EvenDoors::Spin.json_create( JSON.load( json ) )
        json.should eql JSON.generate(dom0)
    end
    #
end
#
#EOF
