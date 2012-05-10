#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe EvenDoors::Board do
    #
    it "require_p release_p" do
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
    it "particle wait and merge" do
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
        # need to set it to p0 too, so case in Board0 is ok
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
# EOF
