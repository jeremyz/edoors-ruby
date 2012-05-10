#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe EvenDoors::Link do
    #
    before(:each) do
        EvenDoors::Spin.clear!
    end
    #
    it "from particle data" do
        p = EvenDoors::Spin.require_p EvenDoors::Particle
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
    it "link->json->link" do
        link = EvenDoors::Link.new  'input1', 'concat1?follow,output1', 'f0,f2', 'f0,f1,f2', 'v0v1v2'
        lnk = EvenDoors::Link.json_create( JSON.load( JSON.generate(link) ) )
        link.src.should eql lnk.src
        link.dsts.should eql lnk.dsts
        link.fields.should eql lnk.fields
        link.cond_fields.should eql lnk.cond_fields
        link.cond_value.should eql lnk.cond_value
    end
    #
end
#
# EOF
