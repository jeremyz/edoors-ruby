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
            class Fake
                attr_reader :p, :sp
                def process_p p
                    @p = p
                end
                def process_sys_p p
                    @sp = p
                end
            end
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
end
