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
require 'iotas'
#
class Fake < Iotas::Spot
    attr_reader :p, :sp, :start, :stop
    def process_p p
        @p = p
    end
    def process_sys_p p
        @sp = p
    end
    def send_p p
        @p = p
    end
    def send_sys_p p
        @sp = p
    end
    def add_spot p
    end
    def start!
        @start=true
    end
    def stop!
        @stop=true
    end
end
#
# EOF
