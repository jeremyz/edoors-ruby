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
    attr_reader :p, :sp
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
end
#
describe EvenDoors do
    #
    it "EvenDoors module should exxists" do
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
        it "link fileds and link value" do
            p = EvenDoors::Particle.new
            p['k0'] = 'v0'
            p['k1'] = 'v1'
            p['k2'] = 'v2'
            p.set_link_fields 'k0,k2'
            p.link_value.should eql 'v0v2'
            p.set_link_fields 'k1,k0'
            p.link_value.should eql 'v1v0'
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
            s0 = EvenDoors::Spot.new '//top', nil
            s1 = EvenDoors::Spot.new '//room0/', s0
            s2 = EvenDoors::Spot.new 'room1', s1
            s3 = EvenDoors::Spot.new 'door///', s2
            s3.path.should eql 'top/room0/room1/door'
        end
        #
    end
    #
    describe EvenDoors::Space do
        #
        it "does really little for now" do
            EvenDoors::Twirl.debug.should be false
            space = EvenDoors::Space.new 'dom0', :debug=>true
            EvenDoors::Twirl.debug.should be true
            space.twirl!
            EvenDoors::Twirl.debug = false
            EvenDoors::Twirl.debug.should be false
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
end
