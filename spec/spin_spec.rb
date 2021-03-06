#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe Edoors::Spin do
    #
    class MyP < Edoors::Particle; end
    #
    it "Particles pool" do
        spin = Edoors::Spin.new 'dom0'
        p0 = spin.require_p Edoors::Particle
        p1 = spin.require_p Edoors::Particle
        expect(p0===p1).to be_falsey
        spin.release_p p0
        p2 = spin.require_p Edoors::Particle
        expect(p0===p2).to be_truthy
    end
    #
    it "different Particles classes in pool" do
        spin = Edoors::Spin.new 'dom0'
        p0 = spin.require_p Edoors::Particle
        p1 = spin.require_p Edoors::Particle
        expect(p0===p1).to be_falsey
        spin.release_p p0
        p2 = spin.require_p MyP
        p3 = spin.require_p MyP
        expect(p2===p3).to be_falsey
        spin.release_p p2
        p4 = spin.require_p MyP
        expect(p2===p4).to be_truthy
    end
    #
    it "release of merged particles" do
        spin = Edoors::Spin.new 'dom0'
        p0 = spin.require_p Edoors::Particle
        p1 = spin.require_p Edoors::Particle
        expect(p0===p1).to be_falsey
        p0.merge! p1
        spin.release_p p0
        p2 = spin.require_p Edoors::Particle
        expect(p2===p0).to be_truthy
        p3 = spin.require_p Edoors::Particle
        expect(p3===p1).to be_truthy
    end
    #
    it "clear!" do
        spin = Edoors::Spin.new 'dom0'
        p0 = spin.require_p Edoors::Particle
        p1 = spin.require_p Edoors::Particle
        spin.send_p p0
        spin.release_p p1
        spin.clear!
        p2 = spin.require_p Edoors::Particle
        expect(p2==p0).to be_falsey
        expect(p2==p1).to be_falsey
    end
    #
    it "post_p post_sys_p spin!" do
        spin = Edoors::Spin.new 'dom0'
        f = Fake.new 'fake', spin
        p0 = spin.require_p Edoors::Particle
        p0.dst_routed!  f
        p1 = spin.require_p Edoors::Particle
        p1.dst_routed!  f
        spin.post_p p0
        spin.post_sys_p p1
        spin.run = true
        spin.spin!
        expect(f.p).to be p0
        expect(f.sp).to be p1
        spin.stop_spinning!
    end
    #
    it "process_sys" do
        spin = Edoors::Spin.new 'dom0'
        p0 = spin.require_p Edoors::Particle
        p0.add_dst 'unknown'
        spin.send_sys_p p0
        spin.spin!
        p1 = spin.require_p Edoors::Particle
        expect(p0).to be p0
    end
    #
    it "option debug" do
        spin = Edoors::Spin.new 'dom0'
        expect(spin.debug_routing).to be false
        expect(spin.debug_garbage).to be false
        spin = Edoors::Spin.new 'dom0', :debug_routing=>true, :debug_garbage=>true
        expect(spin.debug_routing).to be true
        expect(spin.debug_garbage).to be true
    end
    #
    it "search world" do
        spin = Edoors::Spin.new 'dom0', :debug_routing=>true
        r0 = Edoors::Room.new 'r0', spin
        r1 = Edoors::Room.new 'r1', r0
        r2 = Edoors::Room.new 'r2', r1
        expect(spin.search_world(r0.path)).to be r0
        expect(spin.search_world(r1.path)).to be r1
        expect(spin.search_world(r2.path)).to be r2
    end
    #
    it "spin->json->spin" do
        spin = Edoors::Spin.new 'dom0', :debug_routing=>true
        r0 = Edoors::Room.new 'r0', spin
        r1 = Edoors::Room.new 'r1', r0
        r2 = Edoors::Room.new 'r2', r1
        r3 = Edoors::Room.new 'r3', r1
        r4 = Edoors::Room.new 'r4', r3
        d0 = Edoors::Door.new 'd0', r1
        d1 = Edoors::Door.new 'd1', r1
        d2 = Edoors::Door.new 'd2', r2
        p0 = spin.require_p Edoors::Particle
        p1 = spin.require_p Edoors::Particle
        p2 = spin.require_p Edoors::Particle
        spin.post_p p0
        spin.post_p p1
        spin.post_sys_p p2
        json = JSON.generate spin
        dom0 = Edoors::Spin.json_create( JSON.load( json ) )
        expect(json).to eql JSON.generate(dom0)
    end
    #
    it "hibernate! resume!" do
        spin = Edoors::Spin.new 'dom0'
        p0 = spin.require_p Edoors::Particle
        p0.add_dst Edoors::SYS_ACT_HIBERNATE
        Edoors::Room.new 'input', spin
        Edoors::Room.new 'output', spin
        spin.add_link Edoors::Link.new('input', 'output', nil, nil)
        spin.send_sys_p p0
        spin.spin!
        dom0 = Edoors::Spin.resume! spin.hibernate_path
        expect(dom0.name).to eql spin.name
        File.unlink dom0.hibernate_path
    end
    #
end
#
#EOF
