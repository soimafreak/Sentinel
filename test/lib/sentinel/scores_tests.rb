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
##################################################################

#
# Test Scored class
#

require 'test/unit'
require 'sentinel/scores'

class ScoresTest < Test::Unit::TestCase

    #
    # Test the scores to ensure they are appropriet
    #
    #
    # Scores should be 0-100, negative numbers and cores greater than 100 should he handeled with appropriet exeptions
    #
    
    def test_processes
        neg     = -1
        large   = 101
        string  = "test"
        normal  = 50
        zero    = 0
        hundred = 100
        score   = Scores.new
       
        # Set score to neg and check it is not the sane as score.processes (should not have been set)
        assert_not_equal(score.processes = neg, score.processes, "Expected not to be -1") 
        
        # Set score to large check it is not set
        assert_not_equal(score.processes = large, score.processes, "Expected not to be 101")

        # Set score to string
        assert_not_equal(score.processes = string, score.processes, "Expected not to be a string")

        # Set to be nil
        assert_not_equal(score.processes = nil, score.processes, "Expected not to be nil")

        # Test normal assignments
        assert_equal(score.processes = zero, score.processes, "Expected to be true, 0 can be set")^
        assert_equal(score.processes = normal, score.processes, "Expected to be true, numbers between 0 and 100 can be set")
        assert_equal(score.processes = hundred, score.processes, "Expected to be true, 100 can be set") 
    end
    
    def test_process_state
        neg     = -1
        large   = 101
        string  = "test"
        normal  = 50
        zero    = 0
        hundred = 100
        score   = Scores.new
       
        # Set score to neg and check it is not the sane as score.process_state (should not have been set)
        assert_not_equal(score.process_state = neg, score.process_state, "Expected not to be -1") 
        
        # Set score to large check it is not set
        assert_not_equal(score.process_state = large, score.process_state, "Expected not to be 101")

        # Set score to string
        assert_not_equal(score.process_state = string, score.process_state, "Expected not to be a string")

        # Set to be nil
        assert_not_equal(score.process_state = nil, score.process_state, "Expected not to be nil")

        # Test normal assignments
        assert_equal(score.process_state = zero, score.process_state, "Expected to be true, 0 can be set")^
        assert_equal(score.process_state = normal, score.process_state, "Expected to be true, numbers between 0 and 100 can be set")
        assert_equal(score.process_state = hundred, score.process_state, "Expected to be true, 100 can be set") 

    end

    def test_application
        neg     = -1
        large   = 101
        string  = "test"
        normal  = 50
        zero    = 0
        hundred = 100
        score   = Scores.new
       
        # Set score to neg and check it is not the sane as score.application (should not have been set)
        assert_not_equal(score.application = neg, score.application, "Expected not to be -1") 
        
        # Set score to large check it is not set
        assert_not_equal(score.application = large, score.application, "Expected not to be 101")

        # Set score to string
        assert_not_equal(score.application = string, score.application, "Expected not to be a string")

        # Set to be nil
        assert_not_equal(score.application = nil, score.application, "Expected not to be nil")

        # Test normal assignments
        assert_equal(score.application = zero, score.application, "Expected to be true, 0 can be set")^
        assert_equal(score.application = normal, score.application, "Expected to be true, numbers between 0 and 100 can be set")
        assert_equal(score.application = hundred, score.application, "Expected to be true, 100 can be set") 

    end

    def test_application_url
        neg     = -1
        large   = 101
        string  = "test"
        normal  = 50
        zero    = 0
        hundred = 100
        score   = Scores.new
       
        # Set score to neg and check it is not the sane as score.application_url (should not have been set)
        assert_not_equal(score.application_url = neg, score.application_url, "Expected not to be -1") 
        
        # Set score to large check it is not set
        assert_not_equal(score.application_url = large, score.application_url, "Expected not to be 101")

        # Set score to string
        assert_not_equal(score.application_url = string, score.application_url, "Expected not to be a string")

        # Set to be nil
        assert_not_equal(score.application_url = nil, score.application_url, "Expected not to be nil")

        # Test normal assignments
        assert_equal(score.application_url = zero, score.application_url, "Expected to be true, 0 can be set")^
        assert_equal(score.application_url = normal, score.application_url, "Expected to be true, numbers between 0 and 100 can be set")
        assert_equal(score.application_url = hundred, score.application_url, "Expected to be true, 100 can be set") 

    end

    def test_disk_utilisation
        neg     = -1
        large   = 101
        string  = "test"
        normal  = 50
        zero    = 0
        hundred = 100
        score   = Scores.new
       
        # Set score to neg and check it is not the sane as score.disk_utilisation (should not have been set)
        assert_not_equal(score.disk_utilisation = neg, score.disk_utilisation, "Expected not to be -1") 
        
        # Set score to large check it is not set
        assert_not_equal(score.disk_utilisation = large, score.disk_utilisation, "Expected not to be 101")

        # Set score to string
        assert_not_equal(score.disk_utilisation = string, score.disk_utilisation, "Expected not to be a string")

        # Set to be nil
        assert_not_equal(score.disk_utilisation = nil, score.disk_utilisation, "Expected not to be nil")

        # Test normal assignments
        assert_equal(score.disk_utilisation = zero, score.disk_utilisation, "Expected to be true, 0 can be set")^
        assert_equal(score.disk_utilisation = normal, score.disk_utilisation, "Expected to be true, numbers between 0 and 100 can be set")
        assert_equal(score.disk_utilisation = hundred, score.disk_utilisation, "Expected to be true, 100 can be set") 

    end

    def test_memory
        neg     = -1
        large   = 101
        string  = "test"
        normal  = 50
        zero    = 0
        hundred = 100
        score   = Scores.new
       
        # Set score to neg and check it is not the sane as score.memory (should not have been set)
        assert_not_equal(score.memory = neg, score.memory, "Expected not to be -1") 
        
        # Set score to large check it is not set
        assert_not_equal(score.memory = large, score.memory, "Expected not to be 101")

        # Set score to string
        assert_not_equal(score.memory = string, score.memory, "Expected not to be a string")

        # Set to be nil
        assert_not_equal(score.memory = nil, score.memory, "Expected not to be nil")

        # Test normal assignments
        assert_equal(score.memory = zero, score.memory, "Expected to be true, 0 can be set")^
        assert_equal(score.memory = normal, score.memory, "Expected to be true, numbers between 0 and 100 can be set")
        assert_equal(score.memory = hundred, score.memory, "Expected to be true, 100 can be set") 

    end
end
