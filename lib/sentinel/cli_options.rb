#################################################################
##
##   Sentinel - Self healing application monitor
##
##   Author:         Matthew Smith <soimafreak@gmail.com>
##   Site:           http://sentinel.soimafreak.co.uk/
##   Repo:           https://github.com/soimafreak/Sentinel
##
##
##   Copyright:      Copyright (C) 2012, Matthew Smith 
##   License:
##   This program is free software: you can redistribute it and/or modify
##   it under the terms of the GNU General Public License as published by
##   the Free Software Foundation, either version 3 of the License, or
##   (at your option) any later version.
##
##   This program is distributed in the hope that it will be useful,
##   but WITHOUT ANY WARRANTY; without even the implied warranty of
##   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##   GNU General Public License for more details.
##
##   You should have received a copy of the GNU General Public License
##   along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
###################################################################

#
# This class will gathe roptions from the CLI
#

require 'optparse'

class Sentinel::CLIOptions 


    options    =   {}

    optparse = OptionParser.new do|opts|

        # Set a banner, displayed at the top of the help screen.
        opts.banner = "Usage: sentinel.rb [options] argument ..."

        # Define the options, and what they do
        options[:application] = nil
        opts.on( '-a', '--application APPLICATION', String,  'Application owner to monitor i.e. httpd would be apache, tomcat would be tomcat') do |app|
            options[:application] = app
        end
        
        # Alert percent for application memeory
        options[:application_mem_utilisation] = 80
        opts.on( '--application-mem-utilisation INT', Integer,  'Application memory utilisation percentage (rss/vsz)') do |app_mem_util|
            options[:application_mem_utilisation] = app_mem_util
        end

        # URL to check for :application_search_term
        options[:application_url_check] = nil
        opts.on( '--application-url-check string', String,  'Application url to check') do |app_url_check|
            options[:application_url_check] = app_url_check
        end
        
        # Search term to check :application_url_check for
        options[:application_search_term] = nil
        opts.on( '--application-search-term string', String,  'Search term to check against url') do |app_search_term|
            options[:application_search_term] = app_search_term
        end

        # Alert percent for disk utilisation
        options[:disk_utilisation] = 70
        opts.on( '-d', '--disk-utilisation INT', Integer, 'Disk utilisation') do |du|
            options[:disk_utilisation] = du
        end

        # Location of the Log File
        options[:log_location] = "/var/log/"
        opts.on( '-l', '--log-location PATH', 'Directory the log file should be in' ) do |log_location|
            options[:log_location] = log_location
        end

        #  Log level output
        options[:log_level] = "INFO"
        opts.on( '--log-level DEBUG | INFO | WARN | ERROR | FATAL', String, 'Level of Logging required' ) do |log_level|
            options[:log_level] = log_level.upcase
        end

        # Physical memeory over allocation, the percent of over allocation of VSZ memory aggainst physical
        options[:physical_over_alloc] = 250
        opts.on( '--physical-over-alloc INT', Integer, 'Physical memory over allocation percentage') do |poa|
            options[:physical_over_alloc] = poa
        end

        # Swap over allocation, the amount of over allocation of VSZ memory including against swap 
        options[:swap_over_alloc] = 200
        opts.on( '--swap-over-alloc INT', Integer, 'Swap memory over allocation percentage') do |soa|
            options[:swap_over_alloc] = soa
        end
    end
    def get_opts
        return options
    end
end
