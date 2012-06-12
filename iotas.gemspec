#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
$:.push File.expand_path("../lib", __FILE__)
require 'version'
#
Gem::Specification.new do |s|
    s.name = "iotas"
    s.version = Iotas::VERSION
    s.authors = ["Jérémy Zurcher"]
    s.email = ["jeremy@asynk.ch"]
    s.homepage = "http://github.com/jeremyz/edoors-ruby"
    s.summary = %q{ruby rewrite of C++ application framework evenja (http://www.revena.com/evenja)}
    s.description = %q{Evenja propose a data centric paradigm. A traditional programm composed of many functions
    is decomposed into small autonomous modifications applied on the data implemented in different instances of Door base class.
    Routing between these doors is handled through links or user application destinations.}

    s.files = `git ls-files`.split("\n")
    s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    s.require_paths = ["lib"]

    s.add_runtime_dependency "json"
    s.add_development_dependency "rspec", ["~> 2.6"]
    s.add_development_dependency "rake"
end
#
# EOF
