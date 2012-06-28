#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# from the project top directory :
#
# run this script which builds the example system and spin it untill it's empty:
#   $ ruby -Ilib examples/links.rb
#
require 'edoors'
#
class FileReader < Edoors::Door
    #
    def initialize n, p, path
        super n, p
        @file = File.open(path,'r')
    end
    #
    def start!
        # stimulate myself on system boot up
        send_p require_p(Edoors::Particle), Edoors::ACT_GET
    end
    #
    def receive_p p
        if p.action==Edoors::ACT_GET
            # stop everything if EOF reached
            if @file.eof?
                p.reset!
                send_p p, Edoors::ACT_PASS_THROUGH, 'stats'
            else
                p.set_data 'person', JSON.load(@file.readline)
                # will follow the non conditional link.
                # see Room#_send and Room#_try_links
                send_p p
                # stimulate myself
                start!
            end
        end
    end
    #
end
#
class Filter < Edoors::Door
    #
    def receive_p p
        if p.action!=Edoors::ACT_ERROR
            # apply the filter
            h = {
                :old => (p['person']['age']>=18),
                :female => (p['person']['sex']=='f')
            }
            # puts "input : "+h.inspect
            # store the result into one single attribute
            p['filter_value']= h
            # will follow the conditional link.
            # see Room#_send and Room#_try_links
            send_p p
        end
    end
    #
end
#
class Stats < Edoors::Board
    #
    def receive_p p
        return if p.action==Edoors::ACT_ERROR
        if p.action==Edoors::ACT_PASS_THROUGH
            # use this signal to flush all stored data
            flush!
        else
            # restore the Particle into myself
            # send_p p, self.path
            keep! p
        end
    end
    #
end
#
class OutputDoor < Edoors::Door
    #
    #
    def receive_p p
        return if p.action==Edoors::ACT_ERROR
        f = p['filter_value']
        puts "Team #{f[:old] ? 'mature' : 'tean'} #{f[:female] ? 'women' : 'men'} #{} (#{p.merged_length+1})"
        d = p.get_data('person')
        puts " #{d['name']} is #{d['age']} years old"
        p.each_merged do |o|
            d = o.get_data('person')
            puts " #{d['name']} is #{d['age']} years old"
        end
        puts
    end
    #
end
#
if $0 == __FILE__
    # basic setup, see hello_world.rb
    dom0 = Edoors::Spin.new 'dom0'
    #
    FileReader.new 'input', dom0, './examples/data.json'
    # the filter to be applied to each particle
    Filter.new 'filter', dom0
    # the statistics board
    Stats.new 'stats', dom0
    # different outptu doors
    OutputDoor.new 'output', dom0
    # default link directing everything from input into age_filter
    dom0.add_link Edoors::Link.new('input', ['filter','stats?follow','output'], 'filter_value')
    #
    # schedule the spinning particles untill the system cools down
    dom0.spin!
    #
end
#
# EOF
