#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# Copyright 2012 Jérémy Zurcher <jeremy@asynk.ch>
#
# This file is part of iotas.
#
# iotas is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iotas is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with iotas.  If not, see <http://www.gnu.org/licenses/>.

#
module Iotas
    #
    PATH_SEP = '/'.freeze
    LINK_SEP = ','.freeze
    ACT_SEP = '?'.freeze
    #
    ACT_GET = 'get'.freeze
    ACT_ERROR = 'error'.freeze
    #
    SYS_ACT_HIBERNATE = 'hibernate'.freeze
    SYS_ACT_ADD_LINK = 'sys_add_link'.freeze
    #
    FIELD_ERROR_MSG     = 'edoors_error'.freeze
    FIELD_HIBERNATE_PATH= 'hibernate_path'.freeze
    #
    class Exception < ::Exception; end
    #
    VERSION = "0.0.1"
    #
end
#
require 'json'
require 'iotas/particle'
require 'iotas/iota'
require 'iotas/room'
require 'iotas/spin'
require 'iotas/door'
require 'iotas/board'
require 'iotas/link'
#
# EOF
