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

#
module Edoors
    #
    IOTA_NAME   = 'edoors_iota_name'.freeze
    #
    class Iota
        #
        # creates a Iota object from the arguments.
        #
        # @param [String] n the name of this Iota
        # @param [Iota] p the parent
        #
        # @see Room#add_iota adds itself to it's parent children list
        # @see Spin#add_to_world adds itself to @spin's world
        #
        def initialize n, p
            raise Edoors::Exception.new "Iota name #{n} is not valid" if n.include? Edoors::PATH_SEP
            @name   = n     # unique in it's room
            @parent = p     # single direct parent
            @viewer = nil   # particle going through that position will be sent there readonly
            @path = ( @parent ? @parent.path+Edoors::PATH_SEP : '') + @name
            @spin = ( @parent ? @parent.spin : self )
            if @parent
                @parent.add_iota self
                @spin.add_to_world self if @spin.is_a? Edoors::Spin
            end
        end
        #
        attr_reader :name, :path, :spin
        attr_accessor :viewer, :parent
        #
        # override this to initialize your object on system start
        #
        def start!
        end
        #
        # override this to initialize your object on system stop
        #
        def stop!
        end
        #
        # override this to save your object state on hibernate
        # #
        def hibernate!
            {}
        end
        #
        # override this to restore your object state on resume
        #
        def resume! o
        end
        #
        # has to be override, used by user side code
        #
        # @raise NoMethodError
        #
        def receive_p p
            raise NoMethodError.new "#{self.path} receive_p(p) must be overridden"
        end
        #
    end
    #
end
#
# EOF
