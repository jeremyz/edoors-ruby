#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe Edoors::Particle do
    #
    it "payload manipulation" do
        p = Edoors::Particle.new
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
        p = Edoors::Particle.new
        p['k00'] = { 'k0'=>0,'k1'=>1}
        p['k11'] = [1,2,3]
        o = Edoors::Particle.new
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
        spin = Edoors::Spin.new 'dom0'
        p = Edoors::Particle.new
        q = Edoors::Particle.new
        o = Edoors::Particle.new
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
        p.merge! q
        p.merge! o
        p.merged(0).should be q
        p.merged(1).should be o
        p.clear_merged! spin
        p.merged(0).should be_nil
        spin.require_p(Edoors::Particle).should be o
        spin.require_p(Edoors::Particle).should be q
    end
    #
    it "routing: add_dsts, next_dst and dst_routed!" do
        p = Edoors::Particle.new
        d0 = Edoors::Door.new 'door0', nil
        d1 = Edoors::Door.new 'door1', nil
        p.dst.should be_nil
        p.next_dst.should be_nil
        p.add_dsts 'some?where,room0/room1/door?action,room/door,door'
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
    it "wrong path should raise exeption" do
        p = Edoors::Particle.new
        lambda { p.add_dst 'action', '/room' }.should raise_error(Edoors::Exception)
        lambda { p.add_dst 'action', 'room/' }.should raise_error(Edoors::Exception)
        lambda { p.add_dst '', 'room/' }.should raise_error(Edoors::Exception)
        lambda { p.add_dst 'action', 'room//door' }.should raise_error(Edoors::Exception)
        lambda { p.add_dst ' ' }.should raise_error(Edoors::Exception)
        lambda { p.add_dst ' ', '' }.should raise_error(Edoors::Exception)
        lambda { p.add_dst 'f f' }.should raise_error(Edoors::Exception)
        lambda { p.add_dst '', ' d' }.should raise_error(Edoors::Exception)
        lambda { p.add_dst '' }.should raise_error(Edoors::Exception)
        lambda { p.add_dst '', '' }.should raise_error(Edoors::Exception)
        lambda { p.add_dst nil }.should raise_error(TypeError)
        lambda { p.add_dst 'action', nil }.should raise_error(NoMethodError)
    end
    #
    it "routing: set_dst!" do
        p = Edoors::Particle.new
        d0 = Edoors::Door.new 'door0', nil
        #
        p.set_dst! 'action', d0
        p.action.should eql 'action'
        p.dst.should be d0
    end
    #
    it "routing: add_dst and split_dst!" do
        p = Edoors::Particle.new
        d0 = Edoors::Door.new 'door0', nil
        #
        p.split_dst!
        p.room.should be_nil
        p.door.should be_nil
        p.action.should be_nil
        #
        p.add_dst 'action', 'room0/room1/door'
        p.split_dst!
        p.room.should eql 'room0/room1'
        p.door.should eql 'door'
        p.action.should eql 'action'
        p.clear_dsts!
        #
        p.add_dst 'action', 'room/door'
        p.split_dst!
        p.room.should eql 'room'
        p.door.should eql 'door'
        p.action.should eql 'action'
        p.clear_dsts!
        #
        p.add_dst 'action', ''
        p.split_dst!
        p.room.should be_nil
        p.door.should be_nil
        p.action.should eql 'action'
        p.clear_dsts!
        #
        p.add_dst 'action'
        p.split_dst!
        p.room.should be_nil
        p.door.should be_nil
        p.action.should eql 'action'
        p.clear_dsts!
        #
        p.add_dsts 'door?action,?action'
        p.split_dst!
        p.room.should be_nil
        p.door.should eql 'door'
        p.action.should eql 'action'
        #
        p.dst_routed! d0
        #
        p.dst.should be d0
        p.split_dst!
        p.room.should be_nil
        p.door.should be_nil
        p.action.should eql 'action'
        #
    end
    #
    it "routing: error!" do
        p = Edoors::Particle.new
        d = Edoors::Door.new 'door', nil
        p.init! d
        p.add_dsts 'door?action,?action'
        p.next_dst.should eql 'door?action'
        p.error! 'err_msg'
        p[Edoors::FIELD_ERROR_MSG].should eql 'err_msg'
        p.action.should eq Edoors::ACT_ERROR
        p.dst.should be d
    end
    #
    it "link fields and link value" do
        p = Edoors::Particle.new
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
    it "apply_link!" do
        p = Edoors::Particle.new
        p['k0'] = 'v0'
        p['k1'] = 'v1'
        p['k2'] = 'v2'
        p.set_link_fields 'k0,k2'
        p.add_dsts 'door?action,?action'
        p.src.should be_nil
        p.link_value.should eql 'v0v2'
        p.next_dst.should eql 'door?action'
        lnk = Edoors::Link.new('door0', 'door1?get,door2', 'k1', 'f0,f1', 'v0v1')
        f = Fake.new 'fake', nil
        lnk.door = f
        p.apply_link! lnk
        p.src.should be f
        p.next_dst.should eql 'door1?get'
        p.link_value.should eql 'v1'
    end
    #
    it "particle->json->particle" do
        s0 = Edoors::Spin.new 'top'
        s1 = Edoors::Room.new 'room0', s0
        s2 = Edoors::Room.new 'room1', s1
        s3 = Edoors::Door.new 'doora', s2
        s4 = Edoors::Door.new 'doorb', s1
        p0 = Edoors::Particle.new
        p0['k0'] = 'v0'
        p0['k1'] = 'v1'
        p0['k2'] = 'v2'
        p0.init! s3
        p0.set_link_fields 'k0,k2'
        p0.add_dsts 'room0/room1/room2/doorX?myaction,door?action,?action'
        p0.split_dst!
        p1 = Edoors::Particle.new
        p1['k3'] = 'v6'
        p1['k4'] = 'v7'
        p1['k5'] = 'v8'
        p1.init! s3
        p1.dst_routed! s4
        p1.set_link_fields 'k5,k4,k3'
        p1.add_dsts 'room0/room1/door?action,output?action'
        p0.merge! p1
        o = JSON.load( JSON.generate(p0) )
        o['spin'] = s0
        px = Edoors::Particle.json_create( o )
        ((px.ts-p0.ts)<0.5).should be_true
        px.src.should be s3
        px.dst.should be_nil
        px.room.should eql 'room0/room1/room2'
        px.door.should eql 'doorX'
        px.action.should eql 'myaction'
        px.next_dst.should eql 'room0/room1/room2/doorX?myaction'
        px.link_value.should eql 'v0v2'
        px['k0'].should eql 'v0'
        px['k1'].should eql 'v1'
        px['k2'].should eql 'v2'
        py = px.merged(0)
        ((py.ts-p1.ts)<0.5).should be_true
        py.src.should be s3
        py.dst.should be s4
        py.room.should be_nil
        py.door.should be_nil
        py.action.should be_nil
        py.next_dst.should eql 'room0/room1/door?action'
        py.link_value.should eql 'v8v7v6'
        py['k3'].should eql 'v6'
        py['k4'].should eql 'v7'
        py['k5'].should eql 'v8'
        JSON.generate(p0).should eql JSON.generate(px)
    end
    #
end
#
# EOF
