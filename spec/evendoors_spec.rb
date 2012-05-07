#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
begin
    require 'simplecov'
    SimpleCov.start do
        add_filter 'spec'
    end
rescue LoadError
end
#
require 'evendoors'
#
describe EvenDoors do
    #
    it "EvenDoors module should exxists" do
        expect{ EvenDoors }.not_to raise_error(NameError)
    end
    #
    describe EvenDoors::Twirl do
        #
        class MyP < EvenDoors::Particle; end
        #
        it "should correctly manage Particles pool" do
            p0 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p1 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p0===p1).should be_false
            EvenDoors::Twirl.release_p p0
            p2 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p0===p2).should be_true
        end
        #
        it "should correctly manage different Particles classes" do
            p0 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p1 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p0===p1).should be_false
            EvenDoors::Twirl.release_p p0
            p2 = EvenDoors::Twirl.require_p MyP
            p3 = EvenDoors::Twirl.require_p MyP
            (p2===p3).should be_false
            EvenDoors::Twirl.release_p p2
            p4 = EvenDoors::Twirl.require_p MyP
            (p2===p4).should be_true
        end
        #
        it "should correctly release merged data" do
            p0 = EvenDoors::Twirl.require_p EvenDoors::Particle
            p1 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p0===p1).should be_false
            p0.merge! p1
            EvenDoors::Twirl.release_p p0
            p2 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p2===p0).should be_true
            p3 = EvenDoors::Twirl.require_p EvenDoors::Particle
            (p3===p1).should be_true
        end
        #
    end
    #
end
