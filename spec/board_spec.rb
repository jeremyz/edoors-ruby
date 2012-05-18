#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe Iotas::Board do
    #
    before (:all) do
        @spin = Iotas::Spin.new 'dom0'
    end
    #
    before(:each) do
        @spin.clear!
    end
    #
    it "require_p release_p" do
        board = Iotas::Board.new 'hell', @spin
        p0 = board.require_p Iotas::Particle
        p0.src.should be board
        p1 = board.require_p Iotas::Particle
        p1.src.should be board
        (p0===p1).should be_false
        board.release_p p0
        p2 = board.require_p Iotas::Particle
        p2.src.should be board
        (p0===p2).should be_true
    end
    #
    it "particle wait and merge" do
        p0 = Iotas::Particle.new
        p0['k0'] = 'v0'
        p0['k1'] = 'neither'
        p0['k2'] = 'v2'
        p0.set_link_fields 'k0,k2'
        p0.link_value.should eql 'v0v2'
        p1 = Iotas::Particle.new
        p1['k0'] = 'v0'
        p1['k1'] = 'nore'
        p1['k2'] = 'v2'
        p1.set_link_fields 'k0,k2'
        p1.link_value.should eql 'v0v2'
        P0 = p0
        P1 = p1
        class Board0 < Iotas::Board
            attr_reader :ok, :follow
            def receive_p p
                @ok = false
                case p.action
                when Iotas::ACT_FOLLOW
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
        p0.set_dst! Iotas::ACT_FOLLOW
        p0.split_dst!
        p1.set_dst! Iotas::ACT_FOLLOW
        p1.split_dst!
        b0.process_p p1
        b0.ok.should be_true
        b0.follow.should be_true
    end
    #
    it "board->json->board" do
        board = Iotas::Board.new 'hell', @spin
        p0 = Iotas::Particle.new
        p1 = Iotas::Particle.new
        p1['v0']=0
        p1.set_link_fields 'v0'
        board.process_p p0
        board.process_p p1
        hell = Iotas::Board.json_create( JSON.load( JSON.generate(board) ) )
        board.name.should eql hell.name
        JSON.generate(board).should eql JSON.generate(hell)
    end
    #
end
#
# EOF
