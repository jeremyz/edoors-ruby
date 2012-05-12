#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# Copyright 2012 Jérémy Zurcher <jeremy@asynk.ch>
#
# This file is part of evendoors-ruby.
#
# evendoors-ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# evendoors-ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with evendoors-ruby.  If not, see <http://www.gnu.org/licenses/>.

#
module EvenDoors
    #
    PATH_SEP = '/'.freeze
    LINK_SEP = ','.freeze
    ACT_SEP = '?'.freeze
    #
    ACT_GET = 'get'.freeze
    ACT_FOLLOW = 'follow'.freeze
    ACT_ERROR = 'error'.freeze
    #
    SYS_ACT_ADD_LINK = 'sys_add_link'.freeze
    #
    LNK_SRC     = 'edoors_lnk_src'.freeze
    LNK_DSTS    = 'edoors_lnk_dsts'.freeze
    LNK_FIELDS  = 'edoors_lnk_fields'.freeze
    LNK_CONDF   = 'edoors_lnk_condf'.freeze
    LNK_CONDV   = 'edoors_lnk_condv'.freeze
    #
    FIELD_ERROR_MSG     = 'edoors_error'.freeze
    #
    ERROR_ROUTE_NS      = 'routing error: no source'.freeze
    ERROR_ROUTE_RRWD    = 'routing error: right room, wrong door'.freeze
    ERROR_ROUTE_RRNDD   = 'routing error: right room, no drill down'.freeze
    ERROR_ROUTE_TRWR    = 'routing error: top room, wrong room'.freeze
    ERROR_ROUTE_NDNL    = 'routing error: no destination, no link'.freeze
    ERROR_ROUTE_SND     = 'routing error: system no destination'.freeze
    #
    class Exception < ::Exception; end
    #
end
#
require 'json'
require 'evendoors/particle'
require 'evendoors/spot'
require 'evendoors/room'
require 'evendoors/spin'
require 'evendoors/door'
require 'evendoors/board'
require 'evendoors/link'
#
# EOF
