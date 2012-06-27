#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe Edoors::Iota do
    #
    it "path construction" do
        class S<Edoors::Iota
            def add_iota s
            end
        end
        s0 = S.new 'top', nil
        s1 = S.new 'room0', s0
        s2 = S.new 'room1', s1
        s3 = S.new 'door', s2
        s3.path.should eql 'top/room0/room1/door'
        lambda { Edoors::Iota.new('do/or0', nil) }.should raise_error(Edoors::Exception)
        lambda { Edoors::Iota.new('/door0', nil) }.should raise_error(Edoors::Exception)
        lambda { Edoors::Iota.new('door0/', nil) }.should raise_error(Edoors::Exception)
    end
    #
    it 'start! should do nothing' do
        S.new('top', nil).start!.should be_nil
    end
    #
    it 'stop! should do nothing' do
        S.new('top', nil).stop!.should be_nil
    end
    #
    it 'hibernate! should return empty hash'  do
        S.new('top', nil).hibernate!.should be {}
    end
    #
    it 'resume! should do nothing' do
        S.new('top', nil).resume!(nil).should be_nil
    end
    #
    it 'receive_p should raise NoMethodError' do
        lambda { Edoors::Iota.new('top', nil).receive_p nil }.should raise_error(NoMethodError)
    end
    #
end
#
# EOF
