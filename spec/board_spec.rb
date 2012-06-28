#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe Edoors::Board do
    #
    before (:all) do
        @spin = Edoors::Spin.new 'dom0'
    end
    #
    before(:each) do
        @spin.clear!
    end
    #
    it "require_p release_p" do
        board = Edoors::Board.new 'hell', @spin
        p0 = board.require_p
        p1 = board.require_p Edoors::Particle
        (p0===p1).should be_false
        board.release_p p0
        p2 = board.require_p
        (p0===p2).should be_true
    end
    #
    it "particle wait and merge" do
        p0 = Edoors::Particle.new
        p0['k0'] = 'v0'
        p0['k1'] = 'neither'
        p0['k2'] = 'v2'
        p0.set_link_keys 'k0', 'k2'
        p0.link_value.should == {'k0'=>'v0','k2'=>'v2'}
        p1 = Edoors::Particle.new
        p1['k0'] = 'v0'
        p1['k1'] = 'nore'
        p1['k2'] = 'v2'
        p1.set_link_keys 'k0', 'k2'
        p1.link_value.should == {'k0'=>'v0','k2'=>'v2'}
        P0 = p0
        P1 = p1
        class Board0 < Edoors::Board
            attr_reader :ok, :follow, :pass_through
            def receive_p p
                @ok = false
                @pass_through = false
                case p.action
                when Edoors::ACT_PASS_THROUGH
                    @pass_through = true
                when Edoors::ACT_FOLLOW
                    @follow = true
                    @ok = (p===P0 and p.merged(0)===P1)
                else
                    @follow = false
                    @ok = (p===P1 and p.merged(0)===P0)
                end
            end
        end
        b0 = Board0.new 'door0', @spin
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
        # need to set it to p0 too, so case in Board0 is ok
        p0.add_dst Edoors::ACT_FOLLOW
        p0.split_dst!
        p1.add_dst Edoors::ACT_FOLLOW
        p1.split_dst!
        b0.process_p p1
        b0.ok.should be_true
        b0.follow.should be_true
        p2 = b0.require_p
        p2.set_dst! Edoors::ACT_PASS_THROUGH, b0
        b0.process_p p2
        b0.pass_through.should be true
    end
    #
    it "keep! and flush!" do
        b0 = Edoors::Board.new 'hell', @spin
        def b0.receive_p p
            keep! p
        end
        def b0.get k
            @postponed[k]
        end
        p0 = Edoors::Particle.new
        b0.process_p p0
        p1 = Edoors::Particle.new
        p1.set_dst! Edoors::ACT_FOLLOW, b0
        b0.process_p p1
        p2 = Edoors::Particle.new
        p2.set_dst! Edoors::ACT_FOLLOW, b0
        b0.process_p p2
        p3 = Edoors::Particle.new
        p3.set_dst! Edoors::ACT_FOLLOW, b0
        b0.process_p p3
        (b0.get({}).merged_length+1).should == 4
        b0.flush!
        b0.get({}).should be_nil
    end
    #
    it "board->json->board" do
        board = Edoors::Board.new 'hell', @spin
        p0 = Edoors::Particle.new
        p1 = Edoors::Particle.new
        p1['v0']=0
        p1.set_link_keys 'v0'
        board.process_p p0
        board.process_p p1
        hell = Edoors::Board.json_create( JSON.load( JSON.generate(board) ) )
        board.name.should eql hell.name
        JSON.generate(board).should eql JSON.generate(hell)
    end
    #
end
#
# EOF
