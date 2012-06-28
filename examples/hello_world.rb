#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# from the project top directory :
#
# run this script which builds the example system and spin it untill it's empty:
#   $ ruby -Ilib examples/hello_world.rb
#
# or load the system from a JSON specification ( created with dom0.hibernate! )
#   $ ruby -Ilib -r ./examples/hello_world.rb bin/edoors.rb examples/hello_world.json
#
require 'edoors'
#
class InputDoor < Edoors::Door
    #
    # see Iota class for the different methods to override
    def start!
        # stimulate myself on system boot up
        # if an action is set, but no destination is, it will be self.
        # see Door#_send
        send_p require_p(Edoors::Particle), Edoors::ACT_GET
    end
    #
    def receive_p p
        if p.action==Edoors::ACT_GET
            # if desired (not necessary here), call reset! to clear particle's data,
            # meaning merge particle, payload, destinations
            # see Particle#reset!
            p.reset!
            # manipulate the particle's payload
            p.set_data 'txt', "hello world"
            # will follow the non conditional link.
            # see Room#_send and Room#_try_links
            send_p p
        else
            # we can release it or let the Door do it.
            # see Door#process_p
            release_p p
        end
    end
    #
end
#
class OutputDoor < Edoors::Door
    #
    def receive_p p
        if p.action!=Edoors::ACT_ERROR
            puts p.get_data('txt')
        end
        # let the door release the particle
        # see Door#process_p
    end
    #
end
#
if $0 == __FILE__
    #
    # This will schedule the particles and act as the top level Room
    dom0 = Edoors::Spin.new 'dom0'
    # This will feed a receive particle with data and send it back
    input = InputDoor.new 'input', dom0
    # This will output the receive data and let the system recycle the particle
    output = OutputDoor.new 'output', dom0
    # This will be the unconditinal link leading from 'input' to 'output'
    dom0.add_link Edoors::Link.new('input', 'output', nil, nil)
    #
    # schedule the spinning particles untill the system cools down
    dom0.spin!
    #
    # you can save the system state after it's run,
    # but to be able to use it to bootstrap, the hibernation attribute must be set to false
    # otherwise start! method is not called
    # dom0.hibernate! 'hello_world.json'
end
#
# EOF
