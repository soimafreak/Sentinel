#!/usr/bin/ruby

#################################################################
#
#   Sentinel - Self healing application monitor
#
#   Author:         Matthew Smith <soimafreak@gmail.com>
#   Site:           http://sentinel.soimafreak.co.uk/
#   Purpose:        Check health of a process through various means and keep said process operating correctly
#   Date:           27th march 2012
#   Explination:    Sentinel will carry out a number of checks on the health of the application / system 
#                   based on the outcome of these checks certain actions will be taken
#   Requires:       gem install -r log4r
#   Thanks:         http://angrez.blogspot.co.uk/2006/12/log4r-usage-and-examples.html
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

#
#   Requires
#
require 'optparse'
require 'rubygems'
require 'log4r'

#
#   Classes 
#

#   Score

class Score
    attr_accessor :processes, :process_state, :application, :disk_utilisation, :memory
    
    def initialize(processes = 0, process_state = 0, application = 0, disk_utilisation = 0, memory = 0)
        @processes          = 0
        @process_state      = 0
        @application        = 0
        @disk_utilisation   = 0
        @memory             = 0
    end
end

#
# Get options
#

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

optparse = OptionParser.new do|opts|

    # Set a banner, displayed at the top of the help screen.
    opts.banner = "Usage: sentinel.rb [options] argument ..."

    # Define the options, and what they do
    options[:application] = nil
    opts.on( '-a', '--application APPLICATION', String,  'Application owener to monitor i.e. httpd would be apache, tomcat would be tomcat') do |app|
        options[:application] = app
    end
    options[:disk_utilisation] = 70
    opts.on( '-d', '--disk-utilisation INT', Integer, 'Disk utilisation') do |du|
        options[:disk_utilisation] = du
    end
    options[:log_location] = "/var/log/"
    opts.on( '-l', '--log-location PATH', 'Directory the log file should be in' ) do |log_location|
        options[:log_location] = log_location
    end
    options[:processes] = 0
    opts.on( '-p', '--proccesses INT', Integer, 'Number of proccesses expected') do |n|
        options[:processes] = n
    end
    options[:verbose] = false
    opts.on( '-v', '--verbose', 'Output more information' ) do
        options[:verbose] = true
    end
    opts.on( '-h', '--help', 'Display this screen' ) do
            puts opts
            exit
    end
end

optparse.parse!

#
#   initialize variables
#
scores = Score.new

#
#   Set up Logging
#

include Log4r

# Create a logger named 'mylog' that logs to stdout
$log = Logger.new 'sentinel'

# You can use any Outputter here.
$log.outputters = Outputter.stdout if options[:verbose]

# Log level order is DEBUG < INFO < WARN < ERROR < FATAL
$log.level = Log4r::INFO

# Open a new file logger and ask him not to truncate the file before opening.
# FileOutputter.new(nameofoutputter, Hash containing(filename, trunc))
file = FileOutputter.new('fileOutputter', :filename => "#{options[:log_location]}sentinel.log",:trunc => false)

# You can add as many outputters you want. You can add them using reference
# or by name specified while creating
$log.add(file)
# or mylog.add(fileOutputter) : name we have given.

# As I have set my logging level to ERROR. only messages greater than or 
# equal to this level will show. Order is
# DEBUG < INFO < WARN < ERROR < FATAL

# specify the format for the message.
format = PatternFormatter.new(:pattern => "[%l] %d: %m")

# Add formatter to outputter not to logger. 
# So its like this : you add outputter to logger, and add formattters to outputters.
# As we haven't added this formatter to outputter we created to log messages at 
# STDOUT. Log messages at stdout will be simple
# but the log messages in file will be formatted
file.formatter = format

#
#   Get Pids
#

def get_pids (application)
    
    processes = Hash.new 
    array_of_pids = Array.new

    # GET pids / state of "apache" processes
    list_of_pids = `ps -fu #{application} w | awk '{print $2 "," $7}' | grep -ve "^PID"`

    #Convert the list into an array
    array_of_pids=list_of_pids.split("\n")

    # Convert array into hash
    for i in 0...array_of_pids.length
        processes[i] = {"pid"=>array_of_pids[i].to_s.split(",")[0], "state"=>array_of_pids[i].to_s.split(",")[1]}
    end
    return processes
end

#
#   Get status of pid
#

def check_process_state (processes)
#PROCESS STATE CODES
#       Here are the different values that the s, stat and state output specifiers (header "STAT" or "S") will display to describe the state of a process.
#       D    Uninterruptible sleep (usually IO)
#       R    Running or runnable (on run queue)
#       S    Interruptible sleep (waiting for an event to complete)
#       T    Stopped, either by a job control signal or because it is being traced.
#       W    paging (not valid since the 2.6.xx kernel)
#       X    dead (should never be seen)
#       Z    Defunct ("zombie") process, terminated but not reaped by its parent.
    keys = processes.keys
    for key in 0...keys.length
        #print "key \t: ", keys[key], "\n"
        #print "pid \t: ", processes[keys[key]]["pid"], "\n"
        #print "state \t: ", processes[keys[key]]["state"], "\n"
        if (processes[keys[key]]["state"] == "S" || processes[keys[key]]["state"] == "R")
#           print "Process: ", processes[keys[key]]["pid"], " is in a pretty standard sleep or running state\n"
            processes[keys[key]] = {"bad"=>false}
        elsif (processes[keys[key]]["state"] == "Z" || processes[keys[key]]["state"] == "X")
#           print "Process: ", processes[keys[key]]["pid"], " is in a pretty bad way, zombied from parent or Dead!\n"
            processes[keys[key]] = {"bad"=>true}
        end
    end
    
    #For each bad pid add a score
    
    return processes
# Probably need to check the state of the PPID as well
end

#
#   Score number of processes
#

def score_calc_process_numbers (processes, expected)
    score = 0
    if (expected == 0)
        score = 0
    elsif (processes.length < expected || processes.length > expected)
        score = 100
    elsif (processes.length == expected)
        score = 0
    end
    return score
end

#
#   Calculate scores
#

def score_calc_process (processes)
    score   = 0   
    badpids = 0
    keys    = processes.keys
    for key in 0...keys.length
        if (processes[keys[key]]["bad"] == true)
            badpids += 1    
        end
    end
    if (keys.length > 0)
        score = ((badpids.to_f / keys.length.to_f)*100).to_i
    end
    return score
end

def score_calc_disk_utilisation (disks)
    score = 0
    baddisks = 0
    keys = disks.keys
    for key in 0...keys.length
        if (disks[keys[key]]["bad"] == true)
            baddisks += 1
        end
    end
    if (keys.length > 0)
        score = ((baddisks.to_f / keys.length.to_f)*100).to_i
    end
    return score
end

def get_disks 
    disks = Hash.new
    array_of_disks = Array.new

    # GET disk info
    df_out = `df -TPh | grep -ve "^Files" | awk '{ print $NF "," $(NF-1) "," $1 "," $2}'`

    #Convert the list into an array
    array_of_disks=df_out.split("\n")

    # Convert array into hash
    for i in 0...array_of_disks.length
        disks[i] = {"mount"=>array_of_disks[i].to_s.split(",")[0], "utilisation"=>array_of_disks[i].to_s.split(",")[1], "filesystem"=>array_of_disks[i].to_s.split(",")[2], "type"=>array_of_disks[i].to_s.split(",")[3]}
    end

    return disks
end

def check_disk_utilisation(disks, utilisation)

    keys = disks.keys
    
    for key in 0...keys.length
        #print "Count\t: ", keys[key], "\n"
        #print "Mount\t: ", hash_of_disks[keys[key]]["mount"], "\n"
        #print "Utilisation\t: ", hash_of_disks[keys[key]]["utilisation"], "\n"
        #print "File System\t: ", hash_of_disks[keys[key]]["filesystem"], "\n"
        #print "File Type\t: ", hash_of_disks[keys[key]]["type"], "\n\n"
        if (disks[keys[key]]["utilisation"].to_i > utilisation)
            $log.info "#{disks[keys[key]]["mount"]} is #{disks[keys[key]]["utilisation"]} utilised\n"
            disks[keys[key]] = {"bad"=>true}
        end 
    end
    return disks
end

#
#   Main
#

#out = `sleep 30`
#out_es = $?.exitstatus
#out_exited = $?.exited?
#out_ts = $?.termsig
#out_pid = $?.pid
#print "out = ", out, "\n"
#print "return code = ", out_es, "\n"
#print "termsig = ", out_ts, "\n"
#print "pid = ", out_pid, "\n"
#print "Exited? = ", out_exited, "\n"
#print "(simple terminate on process)\n" if out_ts == 15
#print "(kill on process)\n" if out_ts == 9

#
#   Check Process health
#

hash_of_processes = Hash.new 
hash_of_processes = get_pids(options[:application])
hash_of_processes = check_process_state(hash_of_processes)
scores.processes = score_calc_process_numbers(hash_of_processes, options[:processes])
scores.process_state = score_calc_process(hash_of_processes) 
print "Process_state score = ", scores.process_state, "\n"
print "Processes score = ", scores.processes, "\n"


#
#   Check system health
#

hash_of_disks = Hash.new 
hash_of_disks = get_disks()
hash_of_disks = check_disk_utilisation(hash_of_disks,options[:disk_utilisation])
scores.disk_utilisation = score_calc_disk_utilisation(hash_of_disks)
print "Disk utilisation score = ", scores.disk_utilisation, "\n"
