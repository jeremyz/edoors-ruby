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
        p.set_data Edoors::LNK_DSTS, ['concat1?follow','output1']
        p.set_data Edoors::LNK_KEYS, ['f0','f2']
        p.set_data Edoors::LNK_VALUE, {'f0'=>'v0','f1'=>'v1','f2'=>'v2'}
        lnk = Edoors::Link.from_particle p
        expect(lnk.src).to eql 'input1'
        expect(lnk.dsts).to eql ['concat1?follow','output1']
        expect(lnk.keys).to eql ['f0','f2']
        expect(lnk.value).to be == {'f0'=>'v0','f1'=>'v1','f2'=>'v2'}
    end
    #
    it "link->json->link" do
        link = Edoors::Link.new 'input1', ['concat1?follow','output1'], ['f0','f2'], {'f0'=>'v0','f1'=>'v1','f2'=>'v2'}
        lnk = Edoors::Link.json_create( JSON.load( JSON.generate(link) ) )
        expect(link.src).to eql lnk.src
        expect(link.dsts).to eql lnk.dsts
        expect(link.keys).to eql lnk.keys
        expect(link.value).to eql lnk.value
        expect(JSON.generate(link)).to eql JSON.generate(lnk)
    end
    #
end
#
# EOF
