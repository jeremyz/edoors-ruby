#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
begin
    require 'simplecov'
    SimpleCov.start do
        add_filter 'spec'
    end
rescue LoadError
end
#
require 'evendoors'
#
class Fake
    attr_accessor :parent
    attr_reader :p, :sp, :start, :stop
    def name
        "myname"
    end
    def path
        (@parent.nil? ? name : @parent.path+'/'+name )
    end
    def process_p p
        @p = p
    end
    def process_sys_p p
        @sp = p
    end
    def send_p p
        @p = p
    end
    def send_sys_p p
        @sp = p
    end
    def add_spot p
    end
    def start!
        @start=true
    end
    def stop!
        @stop=true
    end
end
#
describe EvenDoors do
    #
    it "EvenDoors module should exists" do
        expect{ EvenDoors }.not_to raise_error(NameError)
    end
    #
    describe EvenDoors::Twirl do
        #
        class MyP < EvenDoors::Particle; end
        #
        it "should correctly manage Particles pool" do
            p0 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p1 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p0===p1).should be_false
            EvenDoors::Twirl.release_p p0
            p2 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p0===p2).should be_true
        end
        #
        it "should correctly manage different Particles classes" do
            p0 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p1 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p0===p1).should be_false
            EvenDoors::Twirl.release_p p0
            p2 = EvenDoors::Twirl.require_p MyP
            p3 = EvenDoors::Twirl.require_p MyP
            (p2===p3).should be_false
            EvenDoors::Twirl.release_p p2
            p4 = EvenDoors::Twirl.require_p MyP
            (p2===p4).should be_true
        end
        #
        it "should correctly release merged data" do
            p0 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p1 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p0===p1).should be_false
            p0.merge! p1
            EvenDoors::Twirl.release_p p0
            p2 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p2===p0).should be_true
            p3 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p3===p1).should be_true
        end
        #
        it "send_p send_sys_p twirl!" do
            f = Fake.new
            p0 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p0.dst_routed!  f
            p1 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p1.dst_routed!  f
            EvenDoors::Twirl.send_p p0
            EvenDoors::Twirl.send_sys_p p1
            EvenDoors::Twirl.run = true
            EvenDoors::Twirl.twirl!
            f.p.should be p0
            f.sp.should be p1
        end
        #
    end
    #
    describe EvenDoors::Particle do
        #
        it "payload manipulation" do
            p = EvenDoors::Particle.new
            #
            p['key']=666
            p['key'].should eql 666
            p.data('key').should eql 666
            p.get_data('key').should eql 666
            #
            p.set_data 'key', 69
            p['key'].should eql 69
            p.data('key').should eql 69
            p.get_data('key').should eql 69
        end
        #
        it "payload clone" do
            p = EvenDoors::Particle.new
            p['k00'] = { 'k0'=>0,'k1'=>1}
            p['k11'] = [1,2,3]
            o = EvenDoors::Particle.new
            o.clone_data p
            p['k00']=nil
            p['k00'].should be_nil
            o['k00']['k0'].should eql 0
            o['k00']['k1'].should eql 1
            p['k11']=nil
            p['k11'].should be_nil
            o['k11'][0].should eql 1
            o['k11'][1].should eql 2
            o['k11'][2].should eql 3
        end
        #
        it "particle merge" do
            p = EvenDoors::Particle.new
            q = EvenDoors::Particle.new
            o = EvenDoors::Particle.new
            p.merge! q
            p.merge! o
            p.merged(0).should be q
            p.merged(1).should be o
            p.merged(2).should be_nil
            p.merged_shift.should be q
            p.merged(0).should be o
            p.merged(1).should be_nil
            p.merged_shift.should be o
            p.merged(0).should be_nil
            p.merge! q
            p.merge! o
            p.merged(0).should be q
            p.merged(1).should be o
            p.clear_merged!
            p.merged(0).should be_nil
        end
        #
        it "routing: add_dsts, next_dst and dst_routed!" do
            p = EvenDoors::Particle.new
            d0 = EvenDoors::Door.new 'door0'
            d1 = EvenDoors::Door.new 'door1'
            p.dst.should be_nil
            p.next_dst.should be_nil
            p.add_dsts 'some?where,///room0///room1/door?action,room/door,door'
            p.next_dst.should eql 'some?where'
            p.dst_routed! d0
            p.dst.should be d0
            p.next_dst.should eql 'room0/room1/door?action'
            p.dst_routed! d1
            p.dst.should be d1
            p.next_dst.should eql 'room/door'
            p.dst_routed! nil
            p.dst.should be_nil
            p.next_dst.should eql 'door'
        end
        #
        it "routing: set_dst! and split_dst!" do
            p = EvenDoors::Particle.new
            d0 = EvenDoors::Door.new 'door0'
            #
            p.set_dst! 'action', 'room0/room1/door'
            p.split_dst!
            p.room.should eql 'room0/room1'
            p.door.should eql 'door'
            p.action.should eql 'action'
            #
            p.set_dst! 'action', '//room////door'
            p.split_dst!
            p.room.should eql 'room'
            p.door.should eql 'door'
            p.action.should eql 'action'
            #
            p.set_dst! 'action', 'room/door'
            p.split_dst!
            p.room.should eql 'room'
            p.door.should eql 'door'
            p.action.should eql 'action'
            #
            p.set_dst! 'action', ''
            p.split_dst!
            p.room.should eql nil
            p.door.should eql nil
            p.action.should eql 'action'
            #
            p.set_dst! 'action'
            p.split_dst!
            p.room.should eql nil
            p.door.should eql nil
            p.action.should eql 'action'
            #
            p.clear_dsts!
            p.add_dsts 'door?action,?action'
            p.split_dst!
            p.room.should eql nil
            p.door.should eql 'door'
            p.action.should eql 'action'
            #
            p.dst_routed! d0
            #
            p.dst.should be d0
            p.split_dst!
            p.room.should eql nil
            p.door.should eql nil
            p.action.should eql 'action'
            #
            p.set_dst! ''
            p.next_dst.should be_nil
            p.split_dst!
            p.room.should be_nil
            p.door.should be_nil
            p.action.should be_nil
            #
            p.set_dst! nil
            p.next_dst.should be_nil
            p.split_dst!
            p.room.should be_nil
            p.door.should be_nil
            p.action.should be_nil
            #
            p.set_dst! ' ', ' '
            p.next_dst.should be_nil
            p.split_dst!
            p.room.should be_nil
            p.door.should be_nil
            p.action.should be_nil
            #
        end
        #
        it "routing: error!" do
            p = EvenDoors::Particle.new
            d = EvenDoors::Door.new 'door'
            p.src = d
            p.add_dsts 'door?action,?action'
            p.next_dst.should eql 'door?action'
            p.error! 'err_msg'
            p[EvenDoors::ERROR_FIELD].should eql 'err_msg'
            p.action.should eq EvenDoors::ACT_ERROR
            p.dst.should be d
        end
        #
        it "link fields and link value" do
            p = EvenDoors::Particle.new
            p['k0'] = 'v0'
            p['k1'] = 'v1'
            p['k2'] = 'v2'
            p.set_link_fields 'k0,k2'
            p.link_value.should eql 'v0v2'
            p.set_link_fields 'k1,k0'
            p.link_value.should eql 'v1v0'
            p['k0']='vx'
            p.link_value.should eql 'v1vx'
        end
        #
        it "apply_link! should work" do
            p = EvenDoors::Particle.new
            p['k0'] = 'v0'
            p['k1'] = 'v1'
            p['k2'] = 'v2'
            p.set_link_fields 'k0,k2'
            p.add_dsts 'door?action,?action'
            p.src.should be_nil
            p.link_value.should eql 'v0v2'
            p.next_dst.should eql 'door?action'
            lnk = EvenDoors::Link.new('door0', 'door1?get,door2', 'k1', 'f0,f1', 'v0v1')
            f = Fake.new
            lnk.door = f
            p.apply_link! lnk
            p.src.should be f
            p.next_dst.should eql 'door1?get'
            p.link_value.should eql 'v1'
        end
        #
    end
    #
    describe EvenDoors::Link do
        #
        it "from particle data" do
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
            p.set_data EvenDoors::LNK_SRC, 'input1'
            p.set_data EvenDoors::LNK_DSTS, 'concat1?follow,output1'
            p.set_data EvenDoors::LNK_FIELDS, 'f0,f2'
            p.set_data EvenDoors::LNK_CONDF, 'f0,f1,f2'
            p.set_data EvenDoors::LNK_CONDV, 'v0v1v2'
            lnk = EvenDoors::Link.from_particle_data p
            lnk.src.should eql 'input1'
            lnk.dsts.should eql 'concat1?follow,output1'
            lnk.fields.should eql 'f0,f2'
            lnk.cond_fields.should eql 'f0,f1,f2'
            lnk.cond_value.should eql 'v0v1v2'
        end
        #
    end
    #
    describe EvenDoors::Link do
        #
        it "path construction should work" do
            s0 = EvenDoors::Spot.new 'top', nil
            s1 = EvenDoors::Spot.new 'room0', s0
            s2 = EvenDoors::Spot.new 'room1', s1
            s3 = EvenDoors::Spot.new 'door', s2
            s3.path.should eql 'top/room0/room1/door'
            lambda { EvenDoors::Spot.new('do/or0', nil) }.should raise_error(EvenDoors::Exception)
            lambda { EvenDoors::Spot.new('/door0', nil) }.should raise_error(EvenDoors::Exception)
            lambda { EvenDoors::Spot.new('door0/', nil) }.should raise_error(EvenDoors::Exception)
        end
        #
    end
    #
    describe EvenDoors::Space do
        #
        it "does really little for now" do
            EvenDoors::Twirl.debug_routing.should be false
            space = EvenDoors::Space.new 'dom0', :debug_routing=>true
            EvenDoors::Twirl.debug_routing.should be true
            space.twirl!
            EvenDoors::Twirl.debug_routing = false
            EvenDoors::Twirl.debug_routing.should be false
            #
            EvenDoors::Twirl.debug_errors.should be false
            space = EvenDoors::Space.new 'dom0', :debug_errors=>true
            EvenDoors::Twirl.debug_errors.should be true
            space.twirl!
            EvenDoors::Twirl.debug_errors = false
            EvenDoors::Twirl.debug_errors.should be false
        end
        #
    end
    #
    describe EvenDoors::Door do
        #
        it "require_p release_p should work" do
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
        it "should work and release lost particles" do
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
            p0 = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p1 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p1.should be p0
            #
            p0.set_dst! 'LOST'
            p0.split_dst!
            d0.process_p p0
            p1 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p1.should be p0
            #
            d0.process_sys_p p0
            p1 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p1.should be p0
        end
        #
    end
    #
    describe EvenDoors::Board do
        #
        it "require_p release_p should work" do
            board = EvenDoors::Board.new 'hell'
            p0 = board.require_p EvenDoors::Particle
            p0.src.should be board
            p1 = board.require_p EvenDoors::Particle
            p1.src.should be board
            (p0===p1).should be_false
            board.release_p p0
            p2 = board.require_p EvenDoors::Particle
            p2.src.should be board
            (p0===p2).should be_true
        end
        #
        it "should" do
            p0 = EvenDoors::Particle.new
            p0['k0'] = 'v0'
            p0['k1'] = 'neither'
            p0['k2'] = 'v2'
            p0.set_link_fields 'k0,k2'
            p0.link_value.should eql 'v0v2'
            p1 = EvenDoors::Particle.new
            p1['k0'] = 'v0'
            p1['k1'] = 'nore'
            p1['k2'] = 'v2'
            p1.set_link_fields 'k0,k2'
            p1.link_value.should eql 'v0v2'
            P0 = p0
            P1 = p1
            class Board0 < EvenDoors::Board
                attr_reader :ok, :follow
                def receive_p p
                    @ok = false
                    case p.action
                    when EvenDoors::ACT_FOLLOW
                        @follow = true
                        @ok = (p===P0 and p.merged(0)===P1)
                    else
                        @follow = false
                        @ok = (p===P1 and p.merged(0)===P0)
                    end
                end
            end
            b0 = Board0.new 'door0'
            b0.process_p p0
            p0.merged(0).should be_nil
            b0.process_p p1
            b0.ok.should be_true
            b0.follow.should be_false
            #
            p1.merged_shift
            #
            b0.process_p p0
            p0.merged(0).should be_nil
            # need to set it to p0 too, so casein Board0 is ok
            p0.set_dst! EvenDoors::ACT_FOLLOW
            p0.split_dst!
            p1.set_dst! EvenDoors::ACT_FOLLOW
            p1.split_dst!
            b0.process_p p1
            b0.ok.should be_true
            b0.follow.should be_true
        end
        #
    end
    #
    describe EvenDoors::Board do
        #
        it "add_spot and add_link correctly" do
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
        it "parent and space should be ok" do
            s = EvenDoors::Space.new 'space'
            r0 = EvenDoors::Room.new 'r0', s
            r1 = EvenDoors::Room.new 'r0', r0
            r2 = EvenDoors::Room.new 'r0', r1
            r2.parent.should be r1
            r1.parent.should be r0
            r0.parent.should be s
            r0.space.should be s
            r1.space.should be s
            r2.space.should be s
        end
        #
        it "route error: no source" do
            room = EvenDoors::Room.new 'room', nil
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
            p.set_dst! 'get', 'room/door'
            room.send_p p
            p.action.should eql EvenDoors::ACT_ERROR
            p[EvenDoors::ERROR_FIELD].should eql EvenDoors::ERROR_ROUTE_NS
            p.dst.should be room.space
        end
        #
        it "route error: no destination no links" do
            room = EvenDoors::Room.new 'room', nil
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
            EvenDoors::Twirl.clear!
            p['f0']='v0'
            p['f1']='v1'
            door0.send_p p
            EvenDoors::Twirl.run = true
            EvenDoors::Twirl.twirl!
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
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
            room0.send_sys_p p
            p.action.should eql EvenDoors::ACT_ERROR
            p[EvenDoors::ERROR_FIELD].should eql EvenDoors::ERROR_ROUTE_SND
        end
        #
        it "system routing success: action only" do
            room0 = EvenDoors::Room.new 'room0', nil
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
            p.set_dst! EvenDoors::SYS_ACT_ADD_LINK
            room0.send_sys_p p
            p.action.should eql EvenDoors::SYS_ACT_ADD_LINK
            p.dst.should be room0.space
        end
        #
        it "system routing success" do
            room0 = EvenDoors::Room.new 'room0', nil
            door0 = EvenDoors::Door.new 'door0', room0
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
            p.set_dst! EvenDoors::SYS_ACT_ADD_LINK, 'room0/door0'
            room0.send_sys_p p
            p.action.should eql EvenDoors::SYS_ACT_ADD_LINK
            p.dst.should be door0
        end
        #
        it "SYS_ACT_ADD_LINK should work" do
            EvenDoors::Twirl.clear!
            space = EvenDoors::Space.new 'space'    # needed to be able to route to door
            room0 = EvenDoors::Room.new 'room0', space
            door0 = EvenDoors::Door.new 'door0', room0
            door1 = EvenDoors::Door.new 'door1', room0
            p0 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p0.set_data EvenDoors::LNK_SRC, 'door0'
            p0.set_data EvenDoors::LNK_DSTS, 'door1'
            p0.set_data EvenDoors::LNK_FIELDS, 'fields'
            p0.set_data EvenDoors::LNK_CONDF, 'f0,f1'
            p0.set_data EvenDoors::LNK_CONDV, 'v0v1'
            p0.set_dst! EvenDoors::SYS_ACT_ADD_LINK, room0.path
            room0.send_sys_p p0
            space.twirl!
            p = EvenDoors::Twirl.require_p EvenDoors::Particle
            p['f0']='v0'
            p['f1']='v1'
            door0.send_p p
            p.action.should be_nil
            p.src.should be door0
            p.dst.should be door1
        end
        #
    end
end
