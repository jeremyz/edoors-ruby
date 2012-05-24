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
    class Iota
        #
        def initialize n, p
            raise Iotas::Exception.new "Iota name #{n} is not valid" if n.include? Iotas::PATH_SEP
            @name   = n     # unique in it's room
            @parent = p     # single direct parent
            @viewer = nil   # particle going through that position will be sent there readonly
            @path = ( @parent ? @parent.path+Iotas::PATH_SEP : '') + @name
            @spin = ( @parent ? @parent.spin : self )
            @parent.add_iota self if @parent
        end
        #
        attr_reader :name, :path, :spin
        attr_accessor :viewer, :parent
        #
        def start!
            # override this to initialize your object on system start
        end
        #
        def stop!
            # override this to initialize your object on system stop
        end
        #
        def hibernate!
            # override this to save your object state on hibernate
            {}
        end
        #
        def resume! o
            # override this to restore your object state on resume
        end
        #
        def receive_p p
            raise NoMethodError.new "receive_p(p) must be overridden"
        end
        #
    end
    #
end
#
# EOF
