#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Board < Door
        #
        def initialize n, p=nil
            super n, p
            @postponed = {}
        end
        #
        def to_json *a
            {
                'kls'       => self.class.name,
                'name'      => @name,
                'postponed' => @postponed
            }.to_json *a
        end
        #
        def self.json_create o
            raise EvenDoors::Exception.new "JSON #{o['kls']} != #{self.name}" if o['kls'] != self.name
            board = self.new o['name']
            o['postponed'].each do |lv,p|
                board.process_p EvenDoors::Particle.json_create p
            end
            board
        end
        #
        def process_p p
            @viewer.receive_p p if @viewer
            if p.action!=EvenDoors::ACT_ERROR
                p2 = @postponed[p.link_value] ||= p
                return if p2==p
                @postponed.delete p.link_value
                p,p2 = p2,p if p.action==EvenDoors::ACT_FOLLOW
                p.merge! p2
            end
            @saved = p
            receive_p p
            garbage if not @saved.nil?
        end
        #
    end
    #
end
#
# EOF
