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
            return if @file.eof?
            p.set_data 'person', JSON.load(@file.readline)
            # will follow the non conditional link.
            # see Room#_send and Room#_try_links
            send_p p
            # stimulate myself
            start!
        end
    end
    #
end
#
class Filter < Edoors::Door
    #
    def initialize n, p, &block
        super n, p
        @filter = block
    end
    #
    def receive_p p
        if p.action!=Edoors::ACT_ERROR
            # apply the filter
            @filter.call p
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
    def initialize n, p, t
        super n, p
        @title = t
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
    Filter.new('age_filter', dom0) { |p| p['old'] = (p['person']['age']>=30); p['sex']=p['person']['sex'] }
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
end
#
# EOF
