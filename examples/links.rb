#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# from the project top directory :
#
# run this script which builds the example system and spin it untill it's empty:
#   $ ruby -Ilib examples/links.rb
#
# or load the system from a JSON specification ( created with dom0.hibernate! )
#   $ ruby -Ilib -r ./examples/links.rb bin/edoors.rb examples/links.json
#
#
require 'edoors'
#
class FileReader < Edoors::Door
    #
    def initialize n, p, path=nil
        super n, p
        @filepath = path
    end
    #
    def hibernate!
        {'filepath'=>@filepath}
    end
    #
    def resume! o
        @filepath = o['filepath']
    end
    #
    def start!
        @file = File.open(@filepath,'r')
        # stimulate myself on system boot up
        send_p require_p(Edoors::Particle), Edoors::ACT_GET
    end
    #
    def receive_p p
        if p.action==Edoors::ACT_GET
            # stop everything if EOF reached
            return if @file.eof?
            p.set_data 'person', JSON.load(@file.readline)
            # will follow the non conditional link.
            # see Room#_send and Room#_try_links
            send_p p
            # stimulate myself
            send_p require_p(Edoors::Particle), Edoors::ACT_GET
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
            p['old'] = (p['person']['age']>=18)
            p['sex'] = p['person']['sex']
            # will follow the conditional link.
            # see Room#_send and Room#_try_links
            send_p p
        end
    end
    #
end
#
class OutputDoor < Edoors::Door
    #
    def initialize n, p, t=nil
        super n, p
        @title = t
    end
    #
    def hibernate!
        {'title'=>@title}
    end
    #
    def resume! o
        @title = o['title']
    end
    #
    def receive_p p
        if p.action!=Edoors::ACT_ERROR
            p = p.get_data('person')
            puts "#{p['name']} is a #{p['age']} year(s) old #{@title}"
        end
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
    Filter.new 'age_filter', dom0
    # different output doors
    OutputDoor.new 'output_f', dom0, 'woman'
    OutputDoor.new 'output_m', dom0, 'man'
    OutputDoor.new 'output_child', dom0, 'child'
    OutputDoor.new 'output_parent', dom0, 'parent'
    # default link directing everything from input into age_filter
    dom0.add_link Edoors::Link.new('input', 'age_filter')
    # different links directing to different outputs depending on 'sex' key
    dom0.add_link Edoors::Link.new('age_filter', 'output_f', nil, {'sex'=>'f'})
    dom0.add_link Edoors::Link.new('age_filter', 'output_m', nil, {'sex'=>'m'})
    # different links directing to different outputs depending on 'old' key
    dom0.add_link Edoors::Link.new('age_filter', 'output_child', nil, {'old'=>false})
    dom0.add_link Edoors::Link.new('age_filter', 'output_parent', nil, {'old'=>true})
    #
    # schedule the spinning particles untill the system cools down
    dom0.spin!
    #
    # you can save the system state after it's run,
    # but to be able to use it to bootstrap, the hibernation attribute must be set to false
    # otherwise start! method is not called
    dom0.hibernate! 'links.json'
    #
end
#
# EOF
