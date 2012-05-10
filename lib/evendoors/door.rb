#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Door < Spot
        #
        def initialize n, p=nil
            super n, p
            @saved = nil
            @parent.add_spot self if @parent
        end
        #
        def to_json *a
            {
                'kls'   => self.class.name,
                'name'  => @name
            }.to_json *a
        end
        #
        def self.json_create o
            raise EvenDoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            self.new o['name']
        end
        #
        def require_p p_kls
            p = EvenDoors::Spin.require_p p_kls
            p.src = self
            p
        end
        #
        def release_p p
            @saved=nil if @saved==p     # particle is released, all is good
            EvenDoors::Spin.release_p p
        end
        #
        def garbage
            puts " * #{path} didn't give back #{p}" if EvenDoors::Spin.debug_errors
            puts "\t#{@saved.data EvenDoors::ERROR_FIELD}" if @saved.action==EvenDoors::ACT_ERROR
            release_p @saved
            @saved = nil
        end
        #
        def process_p p
            @viewer.receive_p p if @viewer
            @saved = p
            receive_p p
            garbage if not @saved.nil?
        end
        #
        def process_sys_p p
            # nothing todo with it now
            EvenDoors::Spin.release_p p
        end
        #
        def send_p p
            p.src = self
            @saved=nil if @saved==p # particle is sent back the data, all is good
            @parent.send_p p        # daddy will know what to do
        end
        #
        def send_sys_p p
            p.src = self
            @saved=nil if @saved==p # particle is sent back the data, all is good
            @parent.send_sys_p p    # daddy will know what to do
        end
        #
    end
    #
end
#
# EOF
