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
# Test class for the CLIOptions class
#

#
# Requires
#

require 'test/unit'
require 'sentinel/cli_options'

class CLIOptionsTest < Test::Unit::TestCase

  #
  # Test that the CLI Options class returns the correct results
  #
  
  def test_application
    existing_application = ["-a","apache"]
    non_existing_application = ["-a","bob"]

    # At the moment, if the application is not running it should not be an allowed option
    assert_not_equal(options = CLIOptions.parse(non_existing_application), options[:application], "Only applications that are running can be monitored") 

  end

  def test_application_mem_utilisation

  end

  def test_application_url_check

  end

  def test_application_search_term

  end

  def test_disk_utilisation

  end

  def test_log_location

  end 
  
  def test_log_level

  end

  def test_physical_over_alloc

  end 

  def test_swap_over_alloc

  end

end
