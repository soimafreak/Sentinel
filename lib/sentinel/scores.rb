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

class Scores

    def initialize(processes = 0, process_state = 0, application = 0, application_url = 0, disk_utilisation = 0, memory = 0)
        @processes          = 0
        @process_state      = 0
        @application        = 0
        @application_url    = 0
        @disk_utilisation   = 0
        @memory             = 0
    end

    def validate (int)
        # Validate the number is..
        # not nil
        # greater than or equal to 0
        # less than or equal to 100
        if (!int.is_a?(Integer)) 
            print "Scores must be an integer\n"
            return false
        elsif (int == nil) 
            print "Scores can not be nil\n"
            return false
        elsif (int < 0) 
            print "Scores must be positive\n"
            return false
        elsif (int > 100) 
            print "Scores must be less than 100\n"
            return false
        else
            # Yay Valid number
            return true
        end
    end

    def processes= (int)
        if (validate(int)) 
            @processes = int
            return true
        else
            print "Processes score not set \n"
            return false
        end
    end
    def processes
        return @processes
    end

    def process_state= (int)
        if (validate(int)) 
            @process_state = int
            return true
        else
            print "Process_state score not set \n"
            return false
        end
    end
    def process_state
        return @process_state
    end

    def application= (int)
        if (validate(int)) 
            @application = int
            return true
        else
            print "Application score not set \n"
            return false
        end
    end
    def application
        return @application
    end

    def application_url= (int)
        if (validate(int)) 
            @application_url = int
            return true
        else
            print "Application_url score not set \n"
            return false
        end
    end
    def application_url
        return @application_url
    end

    def disk_utilisation= (int)
        if (validate(int)) 
            @disk_utilisation = int
            return true
        else
            print "disk_utilisation score not set \n"
            return false
        end
    end
    def disk_utilisation
        return @disk_utilisation
    end

    def memory= (int)
        if (validate(int)) 
            @memory = int
            return true
        else
            print "memory score not set \n"
            return false
        end
    end
    def memory
        return @memory
    end
end
