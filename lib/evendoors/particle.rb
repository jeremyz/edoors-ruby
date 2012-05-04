#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Particle
        #
        def initialize
            reset!
        end
        #
        def reset!
            @ts = Time.now      # creation time
            @src = nil          # Spot.path where it's originated from
            @room = nil
            @door = nil         # Door where it's currently heading to
            @action = nil       # action to perform on the Door
            @dsts = []          # fifo of Spot.path where to travel to
            @link_fields = []   # the fields used to generate the link value
            @link_value = nil   # the value computed with the link_fields values extracted from the payload
                                # used for pearing in Door and linking in routing process
            @payload = {}       # the actual data carried by this particle
            @merged = []        # list of merged particles
        end
        #
        attr_accessor :src
        attr_reader :ts, :room, :door, :action, :link_value
        #
        # routing
        #
        def dst
            @dsts[0]
        end
        #
        def split_dst!
            p, @action = @dsts[0].split EvenDoors::ACT_SEP
            i = p.rindex EvenDoors::PATH_SEP
            if i.nil?
                @room = nil
                door_name = p
            else
                @room = p[0..i-1]
                door_name = p[i+1..-1]
            end
            door_name
        end
        #
        def dst_done! door
            @dsts.shift
            @door = door
        end
        #
        def error! e
            @action = EvenDoors::ACT_ERROR
            @door = @src
            @payload[EvenDoors::ERROR_FIELD]=e
        end
        #
        def clear_dsts!
            @dsts.clear
        end
        #
        def add_dsts paths
            paths.split(EvenDoors::LINK_SEP).each do |path|
                @dsts << path
            end
        end
        #
        def set_dst a, l=nil
            @room = nil
            @door = nil
            @action = nil
            clear_dsts!
            @dsts << ( l ? l.to_str : '' )+EvenDoors::ACT_SEP+a.to_str
        end
        #
        # data manipulation
        #
        def set_data k, v
            @payload[k] = v
            compute_link_value! if @link_fields.include? k
        end
        #
        def get_data k
            @payload[k]
        end
        alias :data :get_data
        #
        def data k
            @payload[k]
        end
        #
        def clone_data p
            @payload = p.payload.clone
        end
        #
        # link value and fields
        #
        def clear_link_fields!
            @link_fields.clear
            compute_link_value!
        end
        #
        def set_link_fields *args
            @link_fields.clear if not @link_fields.empty?
            args.compact!
            args.each do |lfs|
                lfs.split(',').each do |lf|
                    @link_fields << lf
                end
            end
            compute_link_value!
        end
        #
        def compute_link_value!
            @link_value = @link_fields.inject('') { |s,lf| s+=@payload[lf].to_s if @payload[lf]; s }
        end
        #
        # merge particles management
        #
        def merge! p
            @merged << p
        end
        #
        def merged i
            @merged[i]
        end
        #
        def merged_shift
            @merged.shift
        end
        #
    end
    #
end
#
# EOF
