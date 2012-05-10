#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe EvenDoors::Link do
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
end
#
# EOF
