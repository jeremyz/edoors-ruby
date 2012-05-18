#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#

require 'spec_helper'
#
describe Iotas::Iota do
    #
    it "path construction" do
        class S<Iotas::Iota
            def add_iota s
            end
        end
        s0 = S.new 'top', nil
        s1 = S.new 'room0', s0
        s2 = S.new 'room1', s1
        s3 = S.new 'door', s2
        s3.path.should eql 'top/room0/room1/door'
        lambda { Iotas::Iota.new('do/or0', nil) }.should raise_error(Iotas::Exception)
        lambda { Iotas::Iota.new('/door0', nil) }.should raise_error(Iotas::Exception)
        lambda { Iotas::Iota.new('door0/', nil) }.should raise_error(Iotas::Exception)
    end
    #
end
#
# EOF
