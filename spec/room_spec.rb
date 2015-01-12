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
        expect(lambda { Edoors::Door.new('door0', r0) }).to raise_error(Edoors::Exception)
        expect(lambda { r0.add_iota Edoors::Door.new('door1', r0) }).to raise_error(Edoors::Exception)
        r0.add_link Edoors::Link.new 'door0', 'somewhere'
        expect(lambda { r0.add_link(Edoors::Link.new('nowhere', 'somewhere')) }).to raise_error(Edoors::Exception)
    end
    #
    it "start! and stop! should work" do
        r0 = Edoors::Room.new 'room0', @spin
        d0 = Fake.new 'fake', r0
        expect(d0.start).to be_nil
        expect(d0.stop).to be_nil
        r0.start!
        expect(d0.start).to be_truthy
        expect(d0.stop).to be_nil
        r0.stop!
        expect(d0.start).to be_truthy
        expect(d0.stop).to be_truthy
    end
    #
    it "parent, spin and search_down should be ok" do
        r0 = Edoors::Room.new 'r0', @spin
        r1 = Edoors::Room.new 'r1', r0
        r2 = Edoors::Room.new 'r2', r1
        r3 = Edoors::Room.new 'r3', @spin
        r4 = Edoors::Room.new 'r4', r3
        expect(r2.parent).to be r1
        expect(r1.parent).to be r0
        expect(r0.parent).to be @spin
        expect(r0.spin).to be @spin
        expect(r1.spin).to be @spin
        expect(r2.spin).to be @spin
        expect(r3.spin).to be @spin
        expect(@spin.search_down('dom0/r0/r1/r2')).to be r2
        expect(r0.search_down('dom0/r0/r1/r2')).to be r2
        expect(r1.search_down('dom0/r0/r1/r2')).to be r2
        expect(r2.search_down('dom0/r0/r1/r2')).to be r2
        expect(r1.search_down('dom0/r0/r1/r9')).to be nil
        expect(r3.search_down('dom0/r0/r1/r2')).to be nil
        expect(r4.search_down('dom0/r0/r1/r2')).to be nil
    end
    #
    it "routing success (direct add_dst)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new( 'fake', @spin)
        p.add_dst 'get', 'door0'
        room0.send_p p
        expect(p.action).to eql 'get'
        expect(p.dst).to be door0
    end
    #
    it "routing success (direct send to self)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new( 'fake', @spin)
        door0.send_p p, 'get'
        expect(p.action).to eql 'get'
        expect(p.dst).to be door0
    end
    #
    it "routing success (direct send to pointer)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new( 'fake', @spin)
        door0.send_p p, 'get', door0
        expect(p.action).to eql 'get'
        expect(p.dst).to be door0
    end
    #
    it "routing success (direct send to path)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new( 'fake', @spin)
        door0.send_p p, 'get', door0.path
        expect(p.action).to eql 'get'
        expect(p.dst).to be door0
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
        expect(p.action).to eql 'get'
        expect(p.dst).to be door0
    end
    #
    it "route error: no source" do
        room = Edoors::Room.new 'room', @spin
        p = @spin.require_p Edoors::Particle
        p.add_dst 'get', 'room/door'
        room.send_p p
        expect(p.action).to eql Edoors::ACT_ERROR
        expect(p[Edoors::FIELD_ERROR_MSG]).to eql Edoors::ERROR_ROUTE_NS
        expect(p.dst).to be room.spin
    end
    #
    it "route error: no destination no links" do
        room = Edoors::Room.new 'room', @spin
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', @spin)
        room.send_p p
        expect(p.action).to eql Edoors::ACT_ERROR
        expect(p[Edoors::FIELD_ERROR_MSG]).to eql Edoors::ERROR_ROUTE_NDNL
        expect(p.dst).to be p.src
    end
    #
    it "route error: no rooom, wrong door -> right room wrong door" do
        room0 = Edoors::Room.new 'room0', @spin
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', @spin)
        p.add_dst 'get', 'nodoor'
        room0.send_p p
        expect(p.action).to eql Edoors::ACT_ERROR
        expect(p[Edoors::FIELD_ERROR_MSG]).to eql Edoors::ERROR_ROUTE_RRWD
        expect(p.dst).to be p.src
    end
    #
    it "route error: right rooom, wrong door -> right room wrong door" do
        room0 = Edoors::Room.new 'room0', @spin
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', @spin)
        p.add_dst 'get', 'dom0/room0/nodoor'
        room0.send_p p
        expect(p.action).to eql Edoors::ACT_ERROR
        expect(p[Edoors::FIELD_ERROR_MSG]).to eql Edoors::ERROR_ROUTE_RRWD
        expect(p.dst).to be p.src
    end
    #
    it "route error: right room, wrong door through Spin@world -> does not exists" do
        room0 = Edoors::Room.new 'room0', @spin
        room1 = Edoors::Room.new 'room1', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', room0)
        p.add_dst 'get', 'dom0/room0/nodoor'
        room1.send_p p
        expect(p.action).to eql Edoors::ACT_ERROR
        expect(p[Edoors::FIELD_ERROR_MSG]).to eql Edoors::ERROR_ROUTE_DNE
        expect(p.dst).to be p.src
    end
    #
    it "route error: wrong room, right door through Spin@world -> does not exists" do
        room0 = Edoors::Room.new 'room0', @spin
        room1 = Edoors::Room.new 'room1', room0
        p = @spin.require_p Edoors::Particle
        p.init! Fake.new('fake', @spin)
        p.add_dst 'get', 'dom0/noroom/fake'
        room1.send_p p
        expect(p.action).to eql Edoors::ACT_ERROR
        expect(p[Edoors::FIELD_ERROR_MSG]).to eql Edoors::ERROR_ROUTE_DNE
        expect(p.dst).to be p.src
    end
    #
    it "routing ~failure: no door name -> src" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.init! door0
        p.add_dst 'get'
        room0.send_p p
        expect(p.action).to eql 'get'
        expect(p.dst).to be door0
    end
    #
    it "routing success: unconditional link" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        door1 = Edoors::Door.new 'door1', room0
        room0.add_link Edoors::Link.new('door0', 'door1')
        p = @spin.require_p Edoors::Particle
        door0.send_p p
        expect(p.action).to be_nil
        expect(p.dst).to be door1
    end
    #
    it "routing success: conditional link" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        door1 = Edoors::Door.new 'door1', room0
        room0.add_link Edoors::Link.new('door0', 'door1', 'keys', {'f0'=>'v0','f1'=>'v1'})
        p = @spin.require_p Edoors::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        expect(p.action).to be_nil
        expect(p.src).to be door0
        expect(p.dst).to be door1
    end
    #
    it "routing success: more then one matching link" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        class Out < Edoors::Door
            attr_reader :count
            def receive_p p
                @count ||= 0
                expect(['0','1','2'][@count]).to be == p.next_dst
                @count += 1
            end
        end
        door1 = Out.new 'door1', room0
        room0.add_link Edoors::Link.new('door0', ['door1','0'])
        room0.add_link Edoors::Link.new('door0', ['door1','1'], 'keys', {'f0'=>'v0'})
        room0.add_link Edoors::Link.new('door0', ['door1','2'], 'keys', {'f0'=>'v0','f1'=>'v1'})
        room0.add_link Edoors::Link.new('door0', ['door1','3'], 'keys', {'f0'=>'v0','f1'=>'v2'})
        room0.add_link Edoors::Link.new('door0', ['door1','4'], 'keys', {'f0'=>'v0','f2'=>'v1'})
        p = @spin.require_p Edoors::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        @spin.spin!
        expect(door1.count).to eql 3
    end
    #
    it "system route error: system no destination" do
        room0 = Edoors::Room.new 'room0', @spin
        p = @spin.require_p Edoors::Particle
        room0.send_sys_p p
        expect(p.action).to eql Edoors::ACT_ERROR
        expect(p[Edoors::FIELD_ERROR_MSG]).to eql Edoors::ERROR_ROUTE_SND
    end
    #
    it "system routing success: action only" do
        room0 = Edoors::Room.new 'room0', @spin
        p = @spin.require_p Edoors::Particle
        p.add_dst Edoors::SYS_ACT_ADD_LINK
        room0.send_sys_p p
        expect(p.action).to eql Edoors::SYS_ACT_ADD_LINK
        expect(p.dst).to be room0.spin
    end
    #
    it "system routing success (add_dst)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        p.add_dst Edoors::SYS_ACT_ADD_LINK, 'dom0/room0/door0'
        room0.send_sys_p p
        expect(p.action).to eql Edoors::SYS_ACT_ADD_LINK
        expect(p.dst).to be door0
    end
    #
    it "system routing success (send_sys_p)" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        p = @spin.require_p Edoors::Particle
        door0.send_sys_p p, Edoors::SYS_ACT_ADD_LINK
        expect(p.action).to eql Edoors::SYS_ACT_ADD_LINK
        expect(p.dst).to be door0
    end
    #
    it "SYS_ACT_ADD_LINK" do
        room0 = Edoors::Room.new 'room0', @spin
        door0 = Edoors::Door.new 'door0', room0
        door1 = Edoors::Door.new 'door1', room0
        p0 = @spin.require_p Edoors::Particle
        p0.set_data Edoors::LNK_SRC, 'door0'
        p0.set_data Edoors::LNK_DSTS, 'door1'
        p0.set_data Edoors::LNK_KEYS, 'keys'
        p0.set_data Edoors::LNK_VALUE, {'f0'=>'v0','f1'=>'v1'}
        p0.add_dst Edoors::SYS_ACT_ADD_LINK, room0.path
        room0.send_sys_p p0
        @spin.spin!
        p = @spin.require_p Edoors::Particle
        p['f0']='v0'
        p['f1']='v1'
        door0.send_p p
        expect(p.action).to be_nil
        expect(p.src).to be door0
        expect(p.dst).to be door1
    end
    #
    it "SYS_ACT_ADD_ROOM" do
        room0 = Edoors::Room.new 'room0', @spin
        p0 = @spin.require_p Edoors::Particle
        p0.set_data Edoors::IOTA_NAME, 'roomX'
        p0.add_dst Edoors::SYS_ACT_ADD_ROOM, room0.path
        room0.send_sys_p p0
        p1 = @spin.require_p Edoors::Particle
        p1.set_data Edoors::IOTA_NAME, 'roomY'
        p1.set_dst! Edoors::SYS_ACT_ADD_ROOM, room0
        @spin.send_sys_p p1
        @spin.spin!
        expect(@spin.search_world('dom0/room0/roomX')).to be_a Edoors::Room
        expect(@spin.search_world('dom0/room0/roomY')).to be_a Edoors::Room
        expect(@spin.search_world('dom0/room0/roomZ')).to be nil
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
        r1.add_link Edoors::Link.new('d0', 'd1', 'keys', {'f0'=>'v0','f1'=>'v1'})
        r1.add_link Edoors::Link.new('d0', 'd2')
        r1.add_link Edoors::Link.new('d1', 'd0')
        r2.add_link Edoors::Link.new('d2', 'd1', 'fies', {'f5'=>'v9','f1'=>'v1'})
        rx = Edoors::Room.json_create( JSON.load( JSON.generate(r0) ) )
        expect(JSON.generate(r0)).to eql JSON.generate(rx)
    end#
    #
end
#
# EOF
