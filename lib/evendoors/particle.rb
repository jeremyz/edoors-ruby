#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

#
module EvenDoors
    #
    class Particle
        #
        def initialize
            @ts = Time.now      # creation time
            @src = nil          # Spot where it's originated from
            @dst = nil          # Spot where it's heading to
            @room = nil         # Room path part of the current destination
            @door = nil         # Door path part of the current destination
            @action = nil       # action part of the current destination
            @link_value = nil   # the value computed with the link_fields values extracted from the payload
                                # used for pearing Particles in Boards and linking in routing process
            @dsts = []          # fifo of path?action strings where to travel to
            @link_fields = []   # the fields used to generate the link value
            @payload = {}       # the actual data carried by this particle
            @merged = []        # list of merged particles
        end
        #
        def reset!
            @ts = Time.now
            @src = @dst = @room = @door = @action = @link_value = nil
            @dsts.clear
            @link_fields.clear
            @payload.clear
            @merged.clear
        end
        #
        attr_accessor :src
        attr_reader :ts, :dst, :room, :door, :action, :link_value, :payload
        #
        # routing
        #
        def next_dst
            @dsts[0]
        end
        #
        def clear_dsts!
            @dsts.clear
        end
        #
        def add_dsts paths
            paths.split(EvenDoors::LINK_SEP).each do |path|
                @dsts << path.sub(/^\/+/,'').sub(/\/+$/,'').gsub(/\/{2,}/,'/')
            end
        end
        #
        def set_dst! a, d=nil
            @dst = @room = @door = @action = nil
            clear_dsts!
            @dsts << ( d ? d.sub(/^\/+/,'').sub(/\/+$/,'').gsub(/\/{2,}/,'/') : '' )+EvenDoors::ACT_SEP+a.to_str
        end
        #
        def split_dst!
            @dst = nil
            p, @action = next_dst.split EvenDoors::ACT_SEP
            i = p.rindex EvenDoors::PATH_SEP
            if i.nil?
                @room = nil
                @door = p
            else
                @room = p[0..i-1]
                @door = p[i+1..-1]
            end
            @door = nil if @door.empty?
        end
        #
        def dst_routed! dst
            @dst = dst
            @dsts.shift
        end
        #
        def error! e, dst=nil
            @action = EvenDoors::ACT_ERROR
            @dst = dst||@src
            @payload[EvenDoors::ERROR_FIELD]=e
        end
        #
        # data manipulation
        #
        def []=  k, v
            @payload[k]=v
            compute_link_value! if @link_fields.include? k
        end
        #
        def set_data k, v
            @payload[k] = v
            compute_link_value! if @link_fields.include? k
        end
        #
        def []  k
            @payload[k]
        end
        #
        def get_data k
            @payload[k]
        end
        alias :data :get_data
        #
        def clone_data p
            @payload = p.payload.clone
        end
        #
        # link value and fields
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
        def clear_merged!
            @merged.clear
        end
        #
    end
    #
end
#
# EOF
