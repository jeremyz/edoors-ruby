#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe Edoors::Link do
    #
    it "from particle data" do
        @spin = Edoors::Spin.new 'dom0'
        p = @spin.require_p Edoors::Particle
        p.set_data Edoors::LNK_SRC, 'input1'
        p.set_data Edoors::LNK_DSTS, 'concat1?follow,output1'
        p.set_data Edoors::LNK_FIELDS, 'f0,f2'
        p.set_data Edoors::LNK_CONDF, 'f0,f1,f2'
        p.set_data Edoors::LNK_CONDV, 'v0v1v2'
        lnk = Edoors::Link.from_particle_data p
        lnk.src.should eql 'input1'
        lnk.dsts.should eql 'concat1?follow,output1'
        lnk.fields.should eql 'f0,f2'
        lnk.cond_fields.should eql 'f0,f1,f2'
        lnk.cond_value.should eql 'v0v1v2'
    end
    #
    it "link->json->link" do
        link = Edoors::Link.new  'input1', 'concat1?follow,output1', 'f0,f2', 'f0,f1,f2', 'v0v1v2'
        lnk = Edoors::Link.json_create( JSON.load( JSON.generate(link) ) )
        link.src.should eql lnk.src
        link.dsts.should eql lnk.dsts
        link.fields.should eql lnk.fields
        link.cond_fields.should eql lnk.cond_fields
        link.cond_value.should eql lnk.cond_value
        JSON.generate(link).should eql JSON.generate(lnk)
    end
    #
end
#
# EOF
