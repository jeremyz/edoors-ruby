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

require 'version'
#
module Edoors
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
end
#
require 'json'
require 'edoors/particle'
require 'edoors/iota'
require 'edoors/room'
require 'edoors/spin'
require 'edoors/door'
require 'edoors/board'
require 'edoors/link'
#
# EOF
