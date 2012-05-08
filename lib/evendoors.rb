#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
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
    ERROR_FIELD = 'edoors_error'.freeze
    ERROR_ROUTE_NDN     = 'routing error: no door name'.freeze
    ERROR_ROUTE_NMD     = 'routing error: no more destination'.freeze
    ERROR_ROUTE_RRWD    = 'routing error: right room, wrong door'.freeze
    ERROR_ROUTE_TRWR    = 'routing error: top room, wrong room'.freeze
    ERROR_ROUTE_NDNS    = 'routing error: no destination, no source'.freeze
    ERROR_ROUTE_NDNL    = 'routing error: no destination, no link'.freeze
    ERROR_ROUTE_SND     = 'routing error: system no destination'.freeze
    ERROR_ROUTE_SNDNA   = 'routing error: system no door, no action'.freeze
    #
    class Exception < ::Exception; end
    #
end
#
require 'evendoors/particle'
require 'evendoors/spot'
require 'evendoors/twirl'
require 'evendoors/room'
require 'evendoors/space'
require 'evendoors/door'
require 'evendoors/board'
require 'evendoors/link'
#
# EOF
