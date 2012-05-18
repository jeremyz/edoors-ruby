#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe Iotas::Room do
    #
    before (:all) do
        @spin = Iotas::Spin.new 'dom0'
    end
    #
    before(:each) do
        @spin.clear!
    end
    #
    it "add_spot and add_link correctly" do
        r0 = Iotas::Room.new 'room0', @spin
        d0 = Iotas::Door.new 'door0', r0
        lambda { Iotas::Door.new('door0', r0) }.should raise_error(Iotas::Exception)
        lambda { r0.add_spot Iotas::Door.new('door1', r0) }.should raise_error(Iotas::Exception)
        r0.add_link Iotas::Link.new 'door0', 'somewhere'
        lambda { r0.add_link(Iotas::Link.new('nowhere', 'somewhere')) }.should raise_error(Iotas::Exception)
    end
    #
    it "start! and stop! should work" do
        r0 = Iotas::Room.new 'room0', @spin
        d0 = Fake.new 'fake', r0
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
        r0 = Iotas::Room.new 'r0', @spin
        r1 = Iotas::Room.new 'r1', r0
        r2 = Iotas::Room.new 'r2', r1
        r3 = Iotas::Room.new 'r3', @spin
        r4 = Iotas::Room.new 'r4', r3
        r2.parent.should be r1
        r1.parent.should be r0
        r0.parent.should be @spin
        r0.spin.should be @spin
        r1.spin.should be @spin
        r2.spin.should be @spin
        r3.spin.should be @spin
        @spin.search_down('dom0/r0/r1/r2').should be r2
        r0.search_down('dom0/r0/r1/r2').should be r2
        r1.search_down('dom0/r0/r1/r2').should be r2
        r2.search_down('dom0/r0/r1/r2').should be r2
        r1.search_down('dom0/r0/r1/r9').should be nil
        r3.search_down('dom0/r0/r1/r2').should be nil
        r4.search_down('dom0/r0/r1/r2').should be nil
    end
    #
    it "route error: no source" do
        room = Iotas::Room.new 'room', @spin
        p = @spin.require_p Iotas::Particle
        p.set_dst! 'get', 'room/door'
        room.send_p p
        p.action.should eql Iotas::ACT_ERROR
        p[Iotas::FIELD_ERROR_MSG].should eql Iotas::ERROR_ROUTE_NS
        p.dst.should be room.spin
    end
    #
    it "route error: no destination no links" do
        room = Iotas::Room.new 'room', @spin
        p = @spin.require_p Iotas::Particle
        p.src = Fake.new 'fake', @spin
        room.send_p p
        p.action.should eql Iotas::ACT_ERROR
        p[Iotas::FIELD_ERROR_MSG].should eql Iotas::ERROR_ROUTE_NDNL
        p.dst.should be p.src
    end
    #
    it "route error: top room, wrong room" do
        room0 = Iotas::Room.new 'room0', @spin
        room1 = Iotas::Room.new 'room1', room0
        p = @spin.require_p Iotas::Particle
        p.src = Fake.new 'fake', @spin
        p.set_dst! 'get', 'noroom/door'
        room1.send_p p
        p.action.should eql Iotas::ACT_ERROR
        p[Iotas::FIELD_ERROR_MSG].should eql Iotas::ERROR_ROUTE_TRWR
        p.dst.should be p.src
    end
    #
    it "route error: right room, wrong door" do
        room = Iotas::Room.new 'room', @spin
        p = @spin.require_p Iotas::Particle
        p.src = Fake.new 'fake', @spin
        p.set_dst! 'get', 'dom0/room/nodoor'
        room.send_p p
        p.action.should eql Iotas::ACT_ERROR
        p[Iotas::FIELD_ERROR_MSG].should eql Iotas::ERROR_ROUTE_RRWD
        p.dst.should be p.src
    end
    #
    it "route error: right room, wrong door (bubble up)" do
        room0 = Iotas::Room.new 'room0', @spin
        room1 = Iotas::Room.new 'room1', room0
        p = @spin.require_p Iotas::Particle
        p.src = Fake.new 'fake', @spin
        p.set_dst! 'get', 'dom0/room0/nodoor'
        room1.send_p p
        p.action.should eql Iotas::ACT_ERROR
        p[Iotas::FIELD_ERROR_MSG].should eql Iotas::ERROR_ROUTE_RRWD
        p.dst.should be p.src
    end
    #
    it "routing success (direct)" do
        room0 = Iotas::Room.new 'room0', @spin
        door0 = Iotas::Door.new 'door0', room0
        p = @spin.require_p Iotas::Particle
        p.src = Fake.new 'fake', @spin
        p.set_dst! 'get', 'door0'
        room0.send_p p
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "routing success (bubble up the direct door)" do
        room0 = Iotas::Room.new 'room0', @spin
        room1 = Iotas::Room.new 'room1', room0
        door0 = Iotas::Door.new 'door0', room0
        p = @spin.require_p Iotas::Particle
        p.src = Fake.new 'fake', @spin
        p.set_dst! 'get', 'dom0/room0/door0'
        room1.send_p p
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "route success: bubble up x2, drill down x3" do
        room00 = Iotas::Room.new 'room00', @spin
        room01 = Iotas::Room.new 'room01', room00
        room02 = Iotas::Room.new 'room02', room01
        door000 = Iotas::Door.new 'door000', room02
        room10 = Iotas::Room.new 'room10', @spin
        room11 = Iotas::Room.new 'room11', room10
        p = @spin.require_p Iotas::Particle
        p.src = Fake.new 'fake', @spin
        p.set_dst! 'get', 'dom0/room00/room01/room02/door000'
        room11.send_p p
        p.action.should eql 'get'
        p.dst.should be door000
    end
    #
    it "route error: bubble up x2 drill down x2" do
        room00 = Iotas::Room.new 'room00', @spin
        room01 = Iotas::Room.new 'room01', room00
        room02 = Iotas::Room.new 'room02', room01
        door000 = Iotas::Door.new 'door000', room02
        room10 = Iotas::Room.new 'room10', @spin
        room11 = Iotas::Room.new 'room11', room10
        p = @spin.require_p Iotas::Particle
        p.src = Fake.new 'fake', @spin
        p.set_dst! 'get', 'dom0/room00/room01/wrong/door000'
        room11.send_p p
        p.action.should eql Iotas::ACT_ERROR
        p[Iotas::FIELD_ERROR_MSG].should eql Iotas::ERROR_ROUTE_DDWR
        p.dst.should be p.src
    end
    #
    it "routing success: no door name -> src" do
        room0 = Iotas::Room.new 'room0', @spin
        door0 = Iotas::Door.new 'door0', room0
        p = @spin.require_p Iotas::Particle
        p.src = door0
        p.set_dst! 'get'
        room0.send_p p
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "routing success: unconditional link" do
        room0 = Iotas::Room.new 'room0', @spin
        door0 = Iotas::Door.new 'door0', room0
        door1 = Iotas::Door.new 'door1', room0
        room0.add_link Iotas::Link.new('door0', 'door1')
        p = @spin.require_p Iotas::Particle
        door0.send_p p
        p.action.should be_nil
        p.dst.should be door1
    end
    #
    it "routing success: conditional link" do
        room0 = Iotas::Room.new 'room0', @spin
        door0 = Iotas::Door.new 'door0', room0
        door1 = Iotas::Door.new 'door1', room0
        room0.add_link Iotas::Link.new('door0', 'door1', 'fields', 'f0,f1', 'v0v1')
        p = @spin.require_p Iotas::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        p.action.should be_nil
        p.src.should be door0
        p.dst.should be door1
    end
    #
    it "routing success: more then one matching link" do
        room0 = Iotas::Room.new 'room0', @spin
        door0 = Iotas::Door.new 'door0', room0
        class Out < Iotas::Door
            attr_reader :ps
            def receive_p p
                @ps||=[]
                @ps << p
            end
        end
        door1 = Out.new 'door1', room0
        room0.add_link Iotas::Link.new('door0', 'door1')
        room0.add_link Iotas::Link.new('door0', 'door1', 'fields', 'f0,f1', 'v0v1')
        p = @spin.require_p Iotas::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        @spin.spin!
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
        room0 = Iotas::Room.new 'room0', @spin
        p = @spin.require_p Iotas::Particle
        room0.send_sys_p p
        p.action.should eql Iotas::ACT_ERROR
        p[Iotas::FIELD_ERROR_MSG].should eql Iotas::ERROR_ROUTE_SND
    end
    #
    it "system routing success: action only" do
        room0 = Iotas::Room.new 'room0', @spin
        p = @spin.require_p Iotas::Particle
        p.set_dst! Iotas::SYS_ACT_ADD_LINK
        room0.send_sys_p p
        p.action.should eql Iotas::SYS_ACT_ADD_LINK
        p.dst.should be room0.spin
    end
    #
    it "system routing success" do
        room0 = Iotas::Room.new 'room0', @spin
        door0 = Iotas::Door.new 'door0', room0
        p = @spin.require_p Iotas::Particle
        p.set_dst! Iotas::SYS_ACT_ADD_LINK, 'dom0/room0/door0'
        room0.send_sys_p p
        p.action.should eql Iotas::SYS_ACT_ADD_LINK
        p.dst.should be door0
    end
    #
    it "SYS_ACT_ADD_LINK" do
        room0 = Iotas::Room.new 'room0', @spin
        door0 = Iotas::Door.new 'door0', room0
        door1 = Iotas::Door.new 'door1', room0
        p0 = @spin.require_p Iotas::Particle
        p0.set_data Iotas::LNK_SRC, 'door0'
        p0.set_data Iotas::LNK_DSTS, 'door1'
        p0.set_data Iotas::LNK_FIELDS, 'fields'
        p0.set_data Iotas::LNK_CONDF, 'f0,f1'
        p0.set_data Iotas::LNK_CONDV, 'v0v1'
        p0.set_dst! Iotas::SYS_ACT_ADD_LINK, room0.path
        room0.send_sys_p p0
        @spin.spin!
        p = @spin.require_p Iotas::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        p.action.should be_nil
        p.src.should be door0
        p.dst.should be door1
    end
    #
    it "room->json->room" do
        r0 = Iotas::Room.new 'r0', @spin
        r1 = Iotas::Room.new 'r1', r0
        r2 = Iotas::Room.new 'r2', r1
        r3 = Iotas::Room.new 'r3', r1
        r4 = Iotas::Room.new 'r4', r3
        d0 = Iotas::Door.new 'd0', r1
        d1 = Iotas::Door.new 'd1', r1
        d2 = Iotas::Door.new 'd2', r2
        r1.add_link Iotas::Link.new('d0', 'd1', 'fields', 'f0,f1', 'v0v1')
        r1.add_link Iotas::Link.new('d0', 'd2')
        r1.add_link Iotas::Link.new('d1', 'd0')
        r2.add_link Iotas::Link.new('d2', 'd1', 'fies', 'f5,f1', 'v9v1')
        rx = Iotas::Room.json_create( JSON.load( JSON.generate(r0) ) )
        JSON.generate(r0).should eql JSON.generate(rx)
    end#
    #
end
#
# EOF
