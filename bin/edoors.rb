#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# Copyright 2012 Jérémy Zurcher <jeremy@asynk.ch>
#
# This file is part of edoors-ruby.
#
# edoors-ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# edoors-ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with edoors-ruby.  If not, see <http://www.gnu.org/licenses/>.

require 'edoors'
require 'optparse'

@options = { :require=>[] }

@parser ||= OptionParser.new do |opts|
    opts.banner = "Usage: #{$0.split('/').last} [options] config"

    opts.on_tail("-r", "--require", "Print this message")               { puts opts; exit 0 }
    opts.on_tail("-h", "--help", "Print this message")                  { puts opts; exit 0 }
    opts.on_tail("-v", "--version", "Print version info then exit")     { puts "edoors-ruby #{Edoors::VERSION}"; exit 0 }
    opts.on_tail("-l", "--license", "Print license info then exit")     { puts DATA.read; exit 0 }
    opts.on_tail("-r", "--require FILE", "require the library")         { |file| @options[:require] << file }
end

@parser.parse!(ARGV)

config_path = ARGV.shift
if config_path.nil?
    puts "no config file provided, what the hell should I do ?"
    exit 1
end
if not File.exists? config_path
    puts "#{config_path} does not exists."
    exit 1
end

@options[:require].each do |file|
    load file
end

dom0 = Edoors::Spin.resume! config_path
dom0.spin!

__END__

Copyright 2012 Jérémy Zurcher <jeremy@asynk.ch>

edoors-ruby is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

edoors-ruby is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with edoors-ruby.  If not, see <http://www.gnu.org/licenses/>.

