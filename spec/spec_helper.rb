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
require 'evendoors'
#
class Fake
    attr_accessor :parent
    attr_reader :p, :sp, :start, :stop
    def name
        "myname"
    end
    def path
        (@parent.nil? ? name : @parent.path+'/'+name )
    end
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
