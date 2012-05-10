#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe EvenDoors::Room do
    #
    it "add_spot and add_link correctly" do
        EvenDoors::Spin.debug_routing = false
        r0 = EvenDoors::Room.new 'room0', nil
        d0 = EvenDoors::Door.new 'door0', r0
        lambda { EvenDoors::Door.new('door0', r0) }.should raise_error(EvenDoors::Exception)
        lambda { r0.add_spot EvenDoors::Door.new('door1', r0) }.should raise_error(EvenDoors::Exception)
        r0.add_link EvenDoors::Link.new 'door0', 'somewhere'
        lambda { r0.add_link(EvenDoors::Link.new('nowhere', 'somewhere')) }.should raise_error(EvenDoors::Exception)
    end
    #
    it "start! and stop! should work" do
        r0 = EvenDoors::Room.new 'room0', nil
        d0 = Fake.new
        r0.add_spot d0
        d0.start.should be_nil
        d0.stop.should be_nil
        r0.start!
        d0.start.should be_true
        d0.stop.should be_nil
        r0.stop!
        d0.start.should be_true
        d0.stop.should be_true
    end
    #
    it "parent, spin and search_down should be ok" do
        EvenDoors::Spin.spin = nil
        s = EvenDoors::Spin.new 'dom0'
        r0 = EvenDoors::Room.new 'r0', s
        r1 = EvenDoors::Room.new 'r1', r0
        r2 = EvenDoors::Room.new 'r2', r1
        r3 = EvenDoors::Room.new 'r3', s
        r4 = EvenDoors::Room.new 'r4', r3
        r2.parent.should be r1
        r1.parent.should be r0
        r0.parent.should be s
        r0.spin.should be s
        r1.spin.should be s
        r2.spin.should be s
        r3.spin.should be s
        s.search_down('dom0/r0/r1/r2').should be r2
        r0.search_down('dom0/r0/r1/r2').should be r2
        r1.search_down('dom0/r0/r1/r2').should be r2
        r2.search_down('dom0/r0/r1/r2').should be r2
        r1.search_down('dom0/r0/r1/r9').should be nil
        r3.search_down('dom0/r0/r1/r2').should be nil
        r4.search_down('dom0/r0/r1/r2').should be nil
    end
    #
    it "route error: no source" do
        room = EvenDoors::Room.new 'room', nil
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.set_dst! 'get', 'room/door'
        room.send_p p
        p.action.should eql EvenDoors::ACT_ERROR
        p[EvenDoors::ERROR_FIELD].should eql EvenDoors::ERROR_ROUTE_NS
        p.dst.should be room.spin
    end
    #
    it "route error: no destination no links" do
        room = EvenDoors::Room.new 'room', nil
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.src = Fake.new
        room.send_p p
        p.action.should eql EvenDoors::ACT_ERROR
        p[EvenDoors::ERROR_FIELD].should eql EvenDoors::ERROR_ROUTE_NDNL
        p.dst.should be p.src
    end
    #
    it "route error: top room, wrong room" do
        room0 = EvenDoors::Room.new 'room0', nil
        room1 = EvenDoors::Room.new 'room1', room0
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.src = Fake.new
        p.set_dst! 'get', 'noroom/door'
        room1.send_p p
        p.action.should eql EvenDoors::ACT_ERROR
        p[EvenDoors::ERROR_FIELD].should eql EvenDoors::ERROR_ROUTE_TRWR
        p.dst.should be p.src
    end
    #
    it "route error: right room, wrong door" do
        room = EvenDoors::Room.new 'room', nil
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.src = Fake.new
        p.set_dst! 'get', 'room/nodoor'
        room.send_p p
        p.action.should eql EvenDoors::ACT_ERROR
        p[EvenDoors::ERROR_FIELD].should eql EvenDoors::ERROR_ROUTE_RRWD
        p.dst.should be p.src
    end
    #
    it "route error: right room, wrong door (bubble up)" do
        room0 = EvenDoors::Room.new 'room0', nil
        room1 = EvenDoors::Room.new 'room1', room0
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.src = Fake.new
        p.set_dst! 'get', 'room0/nodoor'
        room1.send_p p
        p.action.should eql EvenDoors::ACT_ERROR
        p[EvenDoors::ERROR_FIELD].should eql EvenDoors::ERROR_ROUTE_RRWD
        p.dst.should be p.src
    end
    #
    it "routing success (direct)" do
        room0 = EvenDoors::Room.new 'room0', nil
        door0 = EvenDoors::Door.new 'door0', room0
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.src = Fake.new
        p.set_dst! 'get', 'door0'
        room0.send_p p
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "routing success (bubble up the direct door)" do
        room0 = EvenDoors::Room.new 'room0', nil
        room1 = EvenDoors::Room.new 'room1', room0
        door0 = EvenDoors::Door.new 'door0', room0
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.src = Fake.new
        p.set_dst! 'get', 'room0/door0'
        room1.send_p p
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "route error: right room, no drill down (2xbubble up)" do
        room0 = EvenDoors::Room.new 'room0', nil
        room1 = EvenDoors::Room.new 'room1', room0
        room2 = EvenDoors::Room.new 'room2', room0
        room3 = EvenDoors::Room.new 'room3', room2
        door0 = EvenDoors::Door.new 'door01', room1
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.src = Fake.new
        p.set_dst! 'get', 'room0/room1/door01'
        room3.send_p p
        p.action.should eql EvenDoors::ACT_ERROR
        p[EvenDoors::ERROR_FIELD].should eql EvenDoors::ERROR_ROUTE_RRNDD
        p.dst.should be p.src
    end
    #
    it "routing success: no door name -> src" do
        room0 = EvenDoors::Room.new 'room0', nil
        door0 = EvenDoors::Door.new 'door0', room0
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.src = door0
        p.set_dst! 'get'
        room0.send_p p
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "routing success: unconditional link" do
        room0 = EvenDoors::Room.new 'room0', nil
        door0 = EvenDoors::Door.new 'door0', room0
        door1 = EvenDoors::Door.new 'door1', room0
        room0.add_link EvenDoors::Link.new('door0', 'door1')
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        door0.send_p p
        p.action.should be_nil
        p.dst.should be door1
    end
    #
    it "routing success: conditional link" do
        room0 = EvenDoors::Room.new 'room0', nil
        door0 = EvenDoors::Door.new 'door0', room0
        door1 = EvenDoors::Door.new 'door1', room0
        room0.add_link EvenDoors::Link.new('door0', 'door1', 'fields', 'f0,f1', 'v0v1')
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        p.action.should be_nil
        p.src.should be door0
        p.dst.should be door1
    end
    #
    it "routing success: more then one matching link" do
        room0 = EvenDoors::Room.new 'room0', nil
        door0 = EvenDoors::Door.new 'door0', room0
        class Out < EvenDoors::Door
            attr_reader :ps
            def receive_p p
                @ps||=[]
                @ps << p
            end
        end
        door1 = Out.new 'door1', room0
        room0.add_link EvenDoors::Link.new('door0', 'door1')
        room0.add_link EvenDoors::Link.new('door0', 'door1', 'fields', 'f0,f1', 'v0v1')
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        EvenDoors::Spin.clear!
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        EvenDoors::Spin.run = true
        EvenDoors::Spin.spin!
        door1.ps.length.should eql 2
        p0 = door1.ps[0]
        p0.action.should be_nil
        p0.src.should be door0
        p0.dst.should be door1
        p1 = door1.ps[1]
        p1.action.should be_nil
        p1.src.should be door0
        p1.dst.should be door1
        p1.should be p
    end
    #
    it "system route error: system no destination" do
        room0 = EvenDoors::Room.new 'room0', nil
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        room0.send_sys_p p
        p.action.should eql EvenDoors::ACT_ERROR
        p[EvenDoors::ERROR_FIELD].should eql EvenDoors::ERROR_ROUTE_SND
    end
    #
    it "system routing success: action only" do
        room0 = EvenDoors::Room.new 'room0', nil
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.set_dst! EvenDoors::SYS_ACT_ADD_LINK
        room0.send_sys_p p
        p.action.should eql EvenDoors::SYS_ACT_ADD_LINK
        p.dst.should be room0.spin
    end
    #
    it "system routing success" do
        room0 = EvenDoors::Room.new 'room0', nil
        door0 = EvenDoors::Door.new 'door0', room0
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p.set_dst! EvenDoors::SYS_ACT_ADD_LINK, 'room0/door0'
        room0.send_sys_p p
        p.action.should eql EvenDoors::SYS_ACT_ADD_LINK
        p.dst.should be door0
    end
    #
    it "SYS_ACT_ADD_LINK" do
        EvenDoors::Spin.clear!
        EvenDoors::Spin.spin = nil
        spin = EvenDoors::Spin.new 'dom0'    # needed to be able to route to door
        room0 = EvenDoors::Room.new 'room0', spin
        door0 = EvenDoors::Door.new 'door0', room0
        door1 = EvenDoors::Door.new 'door1', room0
        p0 = EvenDoors::Spin.require_p EvenDoors::Particle
        p0.set_data EvenDoors::LNK_SRC, 'door0'
        p0.set_data EvenDoors::LNK_DSTS, 'door1'
        p0.set_data EvenDoors::LNK_FIELDS, 'fields'
        p0.set_data EvenDoors::LNK_CONDF, 'f0,f1'
        p0.set_data EvenDoors::LNK_CONDV, 'v0v1'
        p0.set_dst! EvenDoors::SYS_ACT_ADD_LINK, room0.path
        room0.send_sys_p p0
        spin.spin!
        p = EvenDoors::Spin.require_p EvenDoors::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        p.action.should be_nil
        p.src.should be door0
        p.dst.should be door1
    end
    #
end
#
# EOF
