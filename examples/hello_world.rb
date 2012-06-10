#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# run from project top directory with : ruby -Ilib examples/hello_world.rb
#
require 'edoors'
#
class InputDoor < Edoors::Door
    #
    def start!
        # stimulate myself
        send_p require_p(Edoors::Particle), Edoors::ACT_GET
    end
    #
    def receive_p p
        if p.action==Edoors::ACT_GET
            p.reset!
            p.set_data 'txt', "hello world"
            send_p p    # will follow the default link
        else
            puts p.action
            # we can release it or let the Door do it
            release_p p
        end
    end
    #
end
#
class OutputDoor < Edoors::Door
    #
    def receive_p p
        puts p.get_data('txt')
        # let the door release it
    end
    #
end
#
if $0 == __FILE__
    #
    dom0 = Edoors::Spin.new 'dom0'
    input = InputDoor.new 'input', dom0
    output = OutputDoor.new 'output', dom0
    dom0.add_link Edoors::Link.new('input', 'output', nil, nil, nil)
    #
    dom0.spin!
    dom0.hibernate!
    #
end
#
# EOF
