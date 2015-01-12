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
        expect(p['key']).to eql 666
        expect(p.data('key')).to eql 666
        expect(p.get_data('key')).to eql 666
        #
        p.set_data 'key', 69
        expect(p['key']).to eql 69
        expect(p.data('key')).to eql 69
        expect(p.get_data('key')).to eql 69
    end
    #
    it "payload clone" do
        p = Edoors::Particle.new
        p['k00'] = { 'k0'=>0,'k1'=>1}
        p['k11'] = [1,2,3]
        o = Edoors::Particle.new
        o.clone_data p
        p['k00']=nil
        expect(p['k00']).to be_nil
        expect(o['k00']['k0']).to eql 0
        expect(o['k00']['k1']).to eql 1
        p['k11']=nil
        expect(p['k11']).to be_nil
        expect(o['k11'][0]).to eql 1
        expect(o['k11'][1]).to eql 2
        expect(o['k11'][2]).to eql 3
    end
    #
    it "particle merge" do
        spin = Edoors::Spin.new 'dom0'
        p = Edoors::Particle.new
        q = Edoors::Particle.new
        o = Edoors::Particle.new
        p.merge! q
        p.merge! o
        expect(p.merged(0)).to be q
        expect(p.merged(1)).to be o
        expect(p.merged(2)).to be_nil
        c = 0
        p.each_merged do |o|
            expect(o).to be p.merged(c)
            c+=1
        end
        expect(c).to be 2
        expect(p.merged_length).to be 2
        expect(p.merged_shift).to be q
        expect(p.merged(0)).to be o
        expect(p.merged(1)).to be_nil
        c = 0
        p.each_merged do |o|
            expect(o).to be p.merged(c)
            c+=1
        end
        expect(c).to be 1
        expect(p.merged_length).to be 1
        expect(p.merged_shift).to be o
        expect(p.merged(0)).to be_nil
        c = 0
        p.each_merged do |o|
            expect(o).to be p.merged(c)
            c+=1
        end
        expect(c).to be 0
        expect(p.merged_length).to be 0
        p.merge! q
        p.merge! o
        expect(p.merged(0)).to be q
        expect(p.merged(1)).to be o
        p.clear_merged!
        expect(p.merged(0)).to be_nil
        p.merge! q
        p.merge! o
        expect(p.merged(0)).to be q
        expect(p.merged(1)).to be o
        p.clear_merged! spin
        expect(p.merged(0)).to be_nil
        expect(spin.require_p(Edoors::Particle)).to be o
        expect(spin.require_p(Edoors::Particle)).to be q
    end
    #
    it "routing: add_dsts, next_dst and dst_routed!" do
        p = Edoors::Particle.new
        d0 = Edoors::Door.new 'door0', nil
        d1 = Edoors::Door.new 'door1', nil
        expect(p.dst).to be_nil
        expect(p.next_dst).to be_nil
        p.add_dsts 'some?where', 'room0/room1/door?action', 'room/door', 'door'
        expect(p.next_dst).to eql 'some?where'
        p.dst_routed! d0
        expect(p.dst).to be d0
        expect(p.next_dst).to eql 'room0/room1/door?action'
        p.dst_routed! d1
        expect(p.dst).to be d1
        expect(p.next_dst).to eql 'room/door'
        p.dst_routed! nil
        expect(p.dst).to be_nil
        expect(p.next_dst).to eql 'door'
    end
    #
    it "wrong path should raise exeption" do
        p = Edoors::Particle.new
        expect(lambda { p.add_dst 'action', '/room' }).to raise_error(Edoors::Exception)
        expect(lambda { p.add_dst 'action', 'room/' }).to raise_error(Edoors::Exception)
        expect(lambda { p.add_dst '', 'room/' }).to raise_error(Edoors::Exception)
        expect(lambda { p.add_dst 'action', 'room//door' }).to raise_error(Edoors::Exception)
        expect(lambda { p.add_dst ' ' }).to raise_error(Edoors::Exception)
        expect(lambda { p.add_dst ' ', '' }).to raise_error(Edoors::Exception)
        expect(lambda { p.add_dst 'f f' }).to raise_error(Edoors::Exception)
        expect(lambda { p.add_dst '', ' d' }).to raise_error(Edoors::Exception)
        expect(lambda { p.add_dst '' }).to raise_error(Edoors::Exception)
        expect(lambda { p.add_dst '', '' }).to raise_error(Edoors::Exception)
        expect(lambda { p.add_dst nil }).to raise_error(TypeError)
        expect(lambda { p.add_dst 'action', nil }).to raise_error(NoMethodError)
    end
    #
    it "routing: set_dst!" do
        p = Edoors::Particle.new
        d0 = Edoors::Door.new 'door0', nil
        #
        p.set_dst! 'action', d0
        expect(p.action).to eql 'action'
        expect(p.dst).to be d0
        #
        p.set_dst! 'action', '/world/room/door'
        expect(p.action).to eql 'action'
        expect(p.dst).to be nil
        expect(p.room).to eql '/world/room'
        expect(p.door).to eql 'door'
    end
    #
    it "routing: add_dst and split_dst!" do
        p = Edoors::Particle.new
        d0 = Edoors::Door.new 'door0', nil
        #
        p.split_dst!
        expect(p.room).to be_nil
        expect(p.door).to be_nil
        expect(p.action).to be_nil
        #
        p.add_dst 'action', 'room0/room1/door'
        p.split_dst!
        expect(p.room).to eql 'room0/room1'
        expect(p.door).to eql 'door'
        expect(p.action).to eql 'action'
        p.clear_dsts!
        #
        p.add_dst 'action', 'room/door'
        p.split_dst!
        expect(p.room).to eql 'room'
        expect(p.door).to eql 'door'
        expect(p.action).to eql 'action'
        p.clear_dsts!
        #
        p.add_dst 'action', ''
        p.split_dst!
        expect(p.room).to be_nil
        expect(p.door).to be_nil
        expect(p.action).to eql 'action'
        p.clear_dsts!
        #
        p.add_dst 'action'
        p.split_dst!
        expect(p.room).to be_nil
        expect(p.door).to be_nil
        expect(p.action).to eql 'action'
        p.clear_dsts!
        #
        p.add_dsts 'door?action', '?action'
        p.split_dst!
        expect(p.room).to be_nil
        expect(p.door).to eql 'door'
        expect(p.action).to eql 'action'
        #
        p.dst_routed! d0
        #
        expect(p.dst).to be d0
        p.split_dst!
        expect(p.room).to be_nil
        expect(p.door).to be_nil
        expect(p.action).to eql 'action'
        #
    end
    #
    it "routing: error!" do
        p = Edoors::Particle.new
        d = Edoors::Door.new 'door', nil
        p.init! d
        p.add_dsts 'door?action', '?action'
        expect(p.next_dst).to eql 'door?action'
        p.error! 'err_msg'
        expect(p[Edoors::FIELD_ERROR_MSG]).to eql 'err_msg'
        expect(p.action).to eq Edoors::ACT_ERROR
        expect(p.dst).to be d
    end
    #
    it "link keys and link values" do
        p = Edoors::Particle.new
        p['k0'] = 'v0'
        p.set_data 'k1', 'v1'
        p['k2'] = 'v2'
        p['k3'] = 'v3'
        p.set_link_keys 'k0', 'k2', 'k1'
        expect(p.link_value).to be == {'k0'=>'v0','k1'=>'v1','k2'=>'v2'}
        p.del_data 'k0'
        expect(p.link_value).to be == {'k1'=>'v1','k2'=>'v2'}
        p.set_link_keys 'k1', 'k0'
        expect(p.link_value).to be == {'k1'=>'v1'}
        p['k1']='vX'
        expect(p.link_value).to be == {'k1'=>'vX'}
    end
    #
    it 'link_with?' do
        p = Edoors::Particle.new
        p['k0'] = 'v0'
        p['k1'] = 'v1'
        p['k2'] = 'v2'
        expect(p.link_with?(Edoors::Link.new('', '', ''))).to be_truthy
        expect(p.link_with?(Edoors::Link.new('', '', '', {'k0'=>'v0','k1'=>'v1'}))).to be_truthy
        expect(p.link_with?(Edoors::Link.new('', '', '', {'k0'=>'v2','k1'=>'v1'}))).to be_falsy
    end
    #
    it "apply_link!" do
        p = Edoors::Particle.new
        p['k0'] = 'v0'
        p['k1'] = 'v1'
        p['k2'] = 'v2'
        p.set_link_keys 'k0', 'k2'
        p.add_dsts 'door?action', '?action'
        expect(p.src).to be_nil
        expect(p.link_value).to be == {'k0'=>'v0','k2'=>'v2'}
        expect(p.next_dst).to eql 'door?action'
        lnk = Edoors::Link.new('door0', ['door1?get','door2'], 'k1', {'f0'=>'v0','f1'=>'v1'})
        f = Fake.new 'fake', nil
        lnk.door = f
        p.apply_link! lnk
        expect(p.src).to be f
        expect(p.next_dst).to eql 'door1?get'
        expect(p.link_value).to be == {'k1'=>'v1'}
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
        p0.set_link_keys 'k0', 'k2'
        p0.add_dsts 'room0/room1/room2/doorX?myaction', 'door?action', '?action'
        p0.split_dst!
        p1 = Edoors::Particle.new
        p1['k3'] = 'v6'
        p1['k4'] = 'v7'
        p1['k5'] = 'v8'
        p1.init! s3
        p1.dst_routed! s4
        p1.set_link_keys 'k5', 'k4', 'k3'
        p1.add_dsts 'room0/room1/door?action', 'output?action'
        p0.merge! p1
        o = JSON.load( JSON.generate(p0) )
        o['spin'] = s0
        px = Edoors::Particle.json_create( o )
        expect(((px.ts-p0.ts)<0.5)).to be_truthy
        expect(px.src).to be s3
        expect(px.dst).to be_nil
        expect(px.room).to eql 'room0/room1/room2'
        expect(px.door).to eql 'doorX'
        expect(px.action).to eql 'myaction'
        expect(px.next_dst).to eql 'room0/room1/room2/doorX?myaction'
        expect(px.link_value).to be == {'k0'=>'v0','k2'=>'v2'}
        expect(px['k0']).to eql 'v0'
        expect(px['k1']).to eql 'v1'
        expect(px['k2']).to eql 'v2'
        py = px.merged(0)
        expect(((py.ts-p1.ts)<0.5)).to be_truthy
        expect(py.src).to be s3
        expect(py.dst).to be s4
        expect(py.room).to be_nil
        expect(py.door).to be_nil
        expect(py.action).to be_nil
        expect(py.next_dst).to eql 'room0/room1/door?action'
        expect(py.link_value).to be == {'k3'=>'v6','k4'=>'v7','k5'=>'v8'}
        expect(py['k3']).to eql 'v6'
        expect(py['k4']).to eql 'v7'
        expect(py['k5']).to eql 'v8'
        expect(JSON.generate(p0)).to eql JSON.generate(px)
    end
    #
end
#
# EOF
