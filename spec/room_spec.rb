#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe Edoors::Room do
    #
    before (:all) do
        @spin = Edoors::Spin.new 'dom0'
    end
    #
    before(:each) do
        @spin.clear!
    end
    #
    it "add_iota and add_link correctly" do
        r0 = Edoors::Room.new 'room0', @spin
        d0 = Edoors::Door.new 'door0', r0
        lambda { Edoors::Door.new('door0', r0) }.should raise_error(Edoors::Exception)
        lambda { r0.add_iota Edoors::Door.new('door1', r0) }.should raise_error(Edoors::Exception)
        r0.add_link Edoors::Link.new 'door0', 'somewhere'
        lambda { r0.add_link(Edoors::Link.new('nowhere', 'somewhere')) }.should raise_error(Edoors::Exception)
    end
    #
    it "start! and stop! should work" do
        r0 = Edoors::Room.new 'room0', @spin
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
        r0 = Edoors::Room.new 'r0', @spin
        r1 = Edoors::Room.new 'r1', r0
        r2 = Edoors::Room.new 'r2', r1
        r3 = Edoors::Room.new 'r3', @spin
        r4 = Edoors::Room.new 'r4', r3
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
    it "routing success (direct add_dst)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new( 'fake', @spin)
        p.add_dst 'get', 'door0'
        room0.send_p p
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "routing success (direct send to self)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new( 'fake', @spin)
        door0.send_p p, 'get'
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "routing success (direct send to pointer)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new( 'fake', @spin)
        door0.send_p p, 'get', door0
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "routing success (direct send to path)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new( 'fake', @spin)
        door0.send_p p, 'get', door0.path
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "routing success through Spin@world" do
        room0 = Edoors::Room.new 'room0', @spin
        room1 = Edoors::Room.new 'room1', room0
        door0 = Edoors::Door.new 'door0', room1
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', @spin)
        p.add_dst 'get', 'dom0/room0/room1/door0'
        room0.send_p p
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "route error: no source" do
        room = Edoors::Room.new 'room', @spin
        p = @spin.require_p Edoors::Particle
        p.add_dst 'get', 'room/door'
        room.send_p p
        p.action.should eql Edoors::ACT_ERROR
        p[Edoors::FIELD_ERROR_MSG].should eql Edoors::ERROR_ROUTE_NS
        p.dst.should be room.spin
    end
    #
    it "route error: no destination no links" do
        room = Edoors::Room.new 'room', @spin
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', @spin)
        room.send_p p
        p.action.should eql Edoors::ACT_ERROR
        p[Edoors::FIELD_ERROR_MSG].should eql Edoors::ERROR_ROUTE_NDNL
        p.dst.should be p.src
    end
    #
    it "route error: no rooom, wrong door -> right room wrong door" do
        room0 = Edoors::Room.new 'room0', @spin
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', @spin)
        p.add_dst 'get', 'nodoor'
        room0.send_p p
        p.action.should eql Edoors::ACT_ERROR
        p[Edoors::FIELD_ERROR_MSG].should eql Edoors::ERROR_ROUTE_RRWD
        p.dst.should be p.src
    end
    #
    it "route error: right rooom, wrong door -> right room wrong door" do
        room0 = Edoors::Room.new 'room0', @spin
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', @spin)
        p.add_dst 'get', 'dom0/room0/nodoor'
        room0.send_p p
        p.action.should eql Edoors::ACT_ERROR
        p[Edoors::FIELD_ERROR_MSG].should eql Edoors::ERROR_ROUTE_RRWD
        p.dst.should be p.src
    end
    #
    it "route error: right room, wrong door through Spin@world -> does not exists" do
        room0 = Edoors::Room.new 'room0', @spin
        room1 = Edoors::Room.new 'room1', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', room0)
        p.add_dst 'get', 'dom0/room0/nodoor'
        room1.send_p p
        p.action.should eql Edoors::ACT_ERROR
        p[Edoors::FIELD_ERROR_MSG].should eql Edoors::ERROR_ROUTE_DNE
        p.dst.should be p.src
    end
    #
    it "route error: wrong room, right door through Spin@world -> does not exists" do
        room0 = Edoors::Room.new 'room0', @spin
        room1 = Edoors::Room.new 'room1', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', @spin)
        p.add_dst 'get', 'dom0/noroom/fake'
        room1.send_p p
        p.action.should eql Edoors::ACT_ERROR
        p[Edoors::FIELD_ERROR_MSG].should eql Edoors::ERROR_ROUTE_DNE
        p.dst.should be p.src
    end
    #
    it "routing ~failure: no door name -> src" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.init! door0
        p.add_dst 'get'
        room0.send_p p
        p.action.should eql 'get'
        p.dst.should be door0
    end
    #
    it "routing success: unconditional link" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        door1 = Edoors::Door.new 'door1', room0
        room0.add_link Edoors::Link.new('door0', 'door1')
        p = @spin.require_p Edoors::Particle
        door0.send_p p
        p.action.should be_nil
        p.dst.should be door1
    end
    #
    it "routing success: conditional link" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        door1 = Edoors::Door.new 'door1', room0
        room0.add_link Edoors::Link.new('door0', 'door1', 'fields', 'f0,f1', 'v0v1')
        p = @spin.require_p Edoors::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        p.action.should be_nil
        p.src.should be door0
        p.dst.should be door1
    end
    #
    it "routing success: more then one matching link" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        class Out < Edoors::Door
            attr_reader :count
            def receive_p p
                @count||=0
                @count += 1
            end
        end
        door1 = Out.new 'door1', room0
        room0.add_link Edoors::Link.new('door0', 'door1')
        room0.add_link Edoors::Link.new('door0', 'door1', 'fields', 'f0,f1', 'v0v1')
        room0.add_link Edoors::Link.new('door0', 'door1', 'fields', 'f0,f1', 'v0v2')
        p = @spin.require_p Edoors::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        @spin.spin!
        door1.count.should eql 2
    end
    #
    it "system route error: system no destination" do
        room0 = Edoors::Room.new 'room0', @spin
        p = @spin.require_p Edoors::Particle
        room0.send_sys_p p
        p.action.should eql Edoors::ACT_ERROR
        p[Edoors::FIELD_ERROR_MSG].should eql Edoors::ERROR_ROUTE_SND
    end
    #
    it "system routing success: action only" do
        room0 = Edoors::Room.new 'room0', @spin
        p = @spin.require_p Edoors::Particle
        p.add_dst Edoors::SYS_ACT_ADD_LINK
        room0.send_sys_p p
        p.action.should eql Edoors::SYS_ACT_ADD_LINK
        p.dst.should be room0.spin
    end
    #
    it "system routing success (add_dst)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.add_dst Edoors::SYS_ACT_ADD_LINK, 'dom0/room0/door0'
        room0.send_sys_p p
        p.action.should eql Edoors::SYS_ACT_ADD_LINK
        p.dst.should be door0
    end
    #
    it "system routing success (send_sys_p)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        door0.send_sys_p p, Edoors::SYS_ACT_ADD_LINK
        p.action.should eql Edoors::SYS_ACT_ADD_LINK
        p.dst.should be door0
    end
    #
    it "SYS_ACT_ADD_LINK" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        door1 = Edoors::Door.new 'door1', room0
        p0 = @spin.require_p Edoors::Particle
        p0.set_data Edoors::LNK_SRC, 'door0'
        p0.set_data Edoors::LNK_DSTS, 'door1'
        p0.set_data Edoors::LNK_FIELDS, 'fields'
        p0.set_data Edoors::LNK_CONDF, 'f0,f1'
        p0.set_data Edoors::LNK_CONDV, 'v0v1'
        p0.add_dst Edoors::SYS_ACT_ADD_LINK, room0.path
        room0.send_sys_p p0
        @spin.spin!
        p = @spin.require_p Edoors::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        p.action.should be_nil
        p.src.should be door0
        p.dst.should be door1
    end
    #
    it "room->json->room" do
        r0 = Edoors::Room.new 'r0', @spin
        r1 = Edoors::Room.new 'r1', r0
        r2 = Edoors::Room.new 'r2', r1
        r3 = Edoors::Room.new 'r3', r1
        r4 = Edoors::Room.new 'r4', r3
        d0 = Edoors::Door.new 'd0', r1
        d1 = Edoors::Door.new 'd1', r1
        d2 = Edoors::Door.new 'd2', r2
        r1.add_link Edoors::Link.new('d0', 'd1', 'fields', 'f0,f1', 'v0v1')
        r1.add_link Edoors::Link.new('d0', 'd2')
        r1.add_link Edoors::Link.new('d1', 'd0')
        r2.add_link Edoors::Link.new('d2', 'd1', 'fies', 'f5,f1', 'v9v1')
        rx = Edoors::Room.json_create( JSON.load( JSON.generate(r0) ) )
        JSON.generate(r0).should eql JSON.generate(rx)
    end#
    #
end
#
# EOF
