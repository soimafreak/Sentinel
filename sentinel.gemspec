#################################################################
#
#   Sentinel - Self healing application monitor
#
#   Author:         Matthew Smith <soimafreak@gmail.com>
#   Site:           http://sentinel.soimafreak.co.uk/
#   Repo:           https://github.com/soimafreak/Sentinel
#
#
#   Copyright:      Copyright (C) 2012, Matthew Smith 
#   License:
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#################################################################

Gem::Specification.new do |s|
    s.name                      = 'sentinel'
    s.version                   = '0.1.0.1.0'
    s.date                      = Date.today.to_s
    s.summary                   = "Sentinel - Self healing application monitor"
    s.description               = "Sentinel checks the health of various services based on specific check criteria to geenerate a score of \"healthyness\" based on the score it will carry out a number of actions."
    s.homepage                  = 'http://sentinel.soimafreak.co.uk/'
    s.license                   = 'GPL-3'
    s.authors                   = ["Matthew Smith"]
    s.email                     = 'soimafreak@gmail.com'
    s.files                     = ["lib/sentinel.rb", "lib/sentinel/scores.rb","bin/sentinel"]
    s.required_ruby_version     = '>= 1.8.7'
    s.requirements              << "RHEL 6 or equivalent"
    s.post_install_message      = "Thanks for using Sentinel"
end
