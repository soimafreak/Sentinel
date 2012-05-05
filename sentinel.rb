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
    options[:application_mem_utilisation] = 80
    opts.on( '--application-mem-utilisation INT', Integer,  'Application memory utilisation percentage (rss/vsz)') do |app_mem_util|
        options[:application_mem_utilisation] = app_mem_util
    end
    options[:disk_utilisation] = 70
    opts.on( '-d', '--disk-utilisation INT', Integer, 'Disk utilisation') do |du|
        options[:disk_utilisation] = du
    end
    options[:log_location] = "/var/log/"
    opts.on( '-l', '--log-location PATH', 'Directory the log file should be in' ) do |log_location|
        options[:log_location] = log_location
    end
    options[:log_level] = "INFO"
    opts.on( '--log-level DEBUG | INFO | WARN | ERROR | FATAL', String, 'Level of Logging required' ) do |log_level|
        options[:log_level] = log_level.upcase
    end
    options[:physical_over_alloc] = 250
    opts.on( '--physical-over-alloc INT', Integer, 'Physical memory over allocation percentage') do |poa|
        options[:physical_over_alloc] = poa
    end
    options[:swap_over_alloc] = 200
    opts.on( '--swap-over-alloc INT', Integer, 'Swap memory over allocation percentage') do |poa|
        options[:swap_over_alloc] = poa
    end
    options[:total_over_alloc] = 150
    opts.on( '--total-over-alloc INT', Integer, 'Total memory over allocation percentage') do |poa|
        options[:total_over_alloc] = poa
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
case options[:log_level]
    when    "DEBUG"
        $log.level = Log4r::DEBUG
    when    "INFO"
        $log.level = Log4r::INFO
    when    "WARN"
        $log.level = Log4r::WARN
    when    "ERROR"
        $log.level = Log4r::ERROR
    when    "FATAL"
        $log.level = Log4r::FATAL
    else
         print "You provided an invalid option: #{options[:log_level]}"
end

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

def get_app_details (application)
    
    processes = Hash.new 
    array_of_pids = Array.new

    # GET pids / state of "apache" processes
    list_of_pids = `ps U #{application} u | awk '{print $2 "," $3 "," $4 "," $5 "," $6 "," $8 "," $9 "," substr($0, index($0,$11))}' | grep -ve "^PID"`

    #Convert the list into an array
    array_of_pids=list_of_pids.split("\n")

    # Convert array into hash
    for i in 0...array_of_pids.length
        processes[i] = {
            "pid"=>array_of_pids[i].to_s.split(",")[0],
            "cpu"=>array_of_pids[i].to_s.split(",")[1],
            "mem"=>array_of_pids[i].to_s.split(",")[2],
            "vsz"=>array_of_pids[i].to_s.split(",")[3],
            "rss"=>array_of_pids[i].to_s.split(",")[4],
            "state"=>array_of_pids[i].to_s.split(",")[5],
            "start"=>array_of_pids[i].to_s.split(",")[6],
            "command"=>array_of_pids[i].to_s.split(",")[7]
        }
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

#       For BSD formats and when the stat keyword is used, additional characters may be displayed:
#       <    high-priority (not nice to other users)
#       N    low-priority (nice to other users)
#       L    has pages locked into memory (for real-time and custom IO)
#       s    is a session leader
#       l    is multi-threaded (using CLONE_THREAD, like NPTL pthreads do)
#       +    is in the foreground process group

    bad_pids = Hash.new
    keys = processes.keys
    for key in 0...keys.length
        $log.debug "key \t: #{keys[key]}"
        $log.debug "pid \t: #{processes[keys[key]]["pid"]}"
        $log.debug "state \t: #{processes[keys[key]]["state"]}"
        case processes[keys[key]]["state"]
            when "S"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state"
                bad_pids[keys[key]] = {"bad"=>false}
            when "SN"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is a low-priority process"
                bad_pids[keys[key]] = {"bad"=>false}
            when "S<s"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is a high-priority session leader"
                bad_pids[keys[key]] = {"bad"=>false}
            when "Ss+"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is a session leader running in the foreground"
                bad_pids[keys[key]] = {"bad"=>false}
            when "Ssl"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is a session leader and multi-threaded"
                bad_pids[keys[key]] = {"bad"=>false}
            when "S<sl"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep and is a session leader, multi-threaded and high-priority"
                bad_pids[keys[key]] = {"bad"=>false}
            when "Ss"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is a session leader"
                bad_pids[keys[key]] = {"bad"=>false}
            when "S+"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is in the foreground"
                bad_pids[keys[key]] = {"bad"=>false}
            when "S<"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state with high-priority"
                bad_pids[keys[key]] = {"bad"=>false}
            when "Sl"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is multi-threaded"
                bad_pids[keys[key]] = {"bad"=>false}
            when "R"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard running state"
                bad_pids[keys[key]] = {"bad"=>false}
            when "R+"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard running state and is in the foreground"
                bad_pids[keys[key]] = {"bad"=>false}
            when "D"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a uninterruptible sleep state"
                processes[keys[key]] = {"bad"=>false}
            when "D+"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a uninterruptible sleep state and is in the foreground"
                bad_pids[keys[key]] = {"bad"=>false}
            when "T"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard stopped state"
                bad_pids[keys[key]] = {"bad"=>false}
            when "W"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard paging state"
                bad_pids[keys[key]] = {"bad"=>false}
            when "X"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a pretty bad way, it is Dead!"
                bad_pids[keys[key]] = {"bad"=>true}
            when "Z"
                $log.debug "Process: #{processes[keys[key]]["pid"]} is in a pretty bad way, it's a Zombie!!"
                bad_pids[keys[key]] = {"bad"=>true}
            else
                $log.error "Process: #{processes[keys[key]]["pid"]} is in an unknown state of '#{processes[keys[key]]["state"]}'" 
                bad_pids[keys[key]] = {"bad"=>true}
        end
    end
    
    #For each bad pid add a score
    
    return bad_pids
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
        score = ((badpids.to_f / keys.length.to_f)*100)
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
        score = ((baddisks.to_f / keys.length.to_f)*100)
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
        $log.debug "Count\t: #{keys[key]}"
        $log.debug "Mount\t: #{disks[keys[key]]["mount"]}"
        $log.debug "Utilisation\t: #{disks[keys[key]]["utilisation"]}"
        $log.debug "File System\t: #{disks[keys[key]]["filesystem"]}"
        $log.debug "File Type\t: #{disks[keys[key]]["type"]}"
        if (disks[keys[key]]["utilisation"].to_i > utilisation)
            $log.debug "#{disks[keys[key]]["mount"]} is #{disks[keys[key]]["utilisation"]} utilised"
            disks[keys[key]] = {"bad"=>true}
        end 
    end
    return disks
end

def get_system_memory ()
    #   Get basic memory information
    physical_mem_total = `free |grep ^Mem | awk '{print $2}'`
    physical_mem_used = `free |grep ^Mem | awk '{print $3}'`
    physical_mem_free = `free |grep ^Mem | awk '{print $4}'`
    swap_mem_total = `free |grep ^Swap | awk '{print $2}'`
    swap_mem_used = `free |grep ^Swap | awk '{print $3}'`
    swap_mem_free = `free |grep ^Swap | awk '{print $4}'`
    memory = Hash.new
    memory["physical"] = {"total"=>physical_mem_total.strip,"used"=>physical_mem_used.strip,"free"=>physical_mem_free.strip}
    memory["swap"] = {"total"=>swap_mem_total.strip,"used"=>swap_mem_used.strip,"free"=>swap_mem_free.strip}
    
    return memory
end

def check_resident_memory (memory)
    list_of_rss_mem = `ps aux | awk '{ print $6}' | grep -ve "^RSS"`
    total_rss = 0 
    score = 0
    #   Loop through and total up RSS memory, should be the same as memory["physical"]["used"] or slightly smaller (calculation differences)
    list_of_rss_mem.each {|mem| total_rss += mem.to_i }
    if ( total_rss > memory["physical"]["used"].to_i ) 
        $log.warn "Resident memory is greater than used physical memory"
        $log.debug "Resident memory = #{total_rss} Used Physical Memory = #{memory["physical"]["used"]}"
        #not sure if it is a real issue or if it's just unfortunate timing so small increase to score
        score = 10
    end
    return score
end

def check_virtual_memory (memory)
    list_of_vsz_mem = `ps aux | awk '{ print $5}' | grep -ve "^VSZ"`
    total_vsz = 0
    physical_over_alloc = 0
    swap_over_alloc = 0
    total_over_alloc = 0
    total_available_mem = 0
    mem_over_alloc = Hash.new
    list_of_vsz_mem.each {|mem| total_vsz += mem.to_i }
    $log.debug "Total Physical memory = #{memory["physical"]["total"]}"
    $log.debug "Total virtual  memory = #{total_vsz}"
    
    #Calculate over allocation
    total_available_mem = (memory["physical"]["total"].to_i + memory["swap"]["total"].to_i)
    physical_over_alloc = ((total_vsz.to_f / memory["physical"]["total"].to_f) * 100)
    swap_over_alloc = ((total_vsz.to_f / memory["swap"]["total"].to_f) * 100)
    total_over_alloc = ((total_vsz.to_f / total_available_mem.to_f) * 100)
    
    $log.debug "Physical Over allocation = #{physical_over_alloc}%"
    $log.debug "Swap Over allocation = #{swap_over_alloc}%"
    $log.debug "Total Over allocation = #{total_over_alloc}%"
    mem_over_alloc["over_alloc"] = {"physical"=>physical_over_alloc,"swap"=>swap_over_alloc,"total"=>total_over_alloc}
    return mem_over_alloc
end

def check_app_memory (application)
    keys    = application.keys
    app_memory = Hash.new
    for key in 0...keys.length
        $log.debug "pid \t: #{application[keys[key]]["pid"]}"
        $log.debug "Percent of total Memory \t: #{application[keys[key]]["mem"]}"
        $log.debug "Virtual memory size \t: #{application[keys[key]]["vsz"]}"
        $log.debug "Resident Set Size \t: #{application[keys[key]]["rss"]}"

        used_allocation =((application[keys[key]]["rss"].to_f / application[keys[key]]["vsz"].to_f) * 100)
        $log.debug "Percent of used allocation \t: #{used_allocation}"

        app_memory[keys[key]] = {
            "pid"=>application[keys[key]]["pid"],
            "mem_of_total"=>application[keys[key]]["mem"],
            "used_allocation"=>used_allocation
        }
    end
    return app_memory
end

def score_calc_memory (memory,physical_over_alloc,swap_over_alloc,total_over_alloc)
    score_virtual = Hash.new
    score_resident = 0
    score = 0

    #   Gather Resident Scors
    score_resident = check_resident_memory(memory)
    mem_over_alloc = check_virtual_memory(memory)
    
    #   Add the resident score on the off chance it has a value
    score = score_resident
    if (mem_over_alloc["over_alloc"]["physical"].to_i >= physical_over_alloc)
        score += 100
    end
    if (mem_over_alloc["over_alloc"]["swap"].to_i >= swap_over_alloc)
        score += 100
    end
    if (mem_over_alloc["over_alloc"]["total"].to_i >= total_over_alloc)
        score += 100
    end

    return score
end

def score_calc_app_memory (app_memory, app_mem_utilisation)
    keys = app_memory.keys
    score =  0
    mem_of_total = 0.0
    for key in 0...keys.length
        mem_of_total += app_memory[keys[key]]["mem_of_total"].to_f
        if (app_memory[keys[key]]["used_allocation"] >= app_mem_utilisation)
            $log.debug "Application is using more than #{app_mem_utilisation}% of memory allocated to this thread ( #{app_memory[keys[key]]["pid"]})"
            score += 50
        end
    end
    if (mem_of_total >= app_mem_utilisation)
        $log.debug "Application is usinig more than #{app_mem_utilisation}% of total memory"
        score += 100
    end
    $log.debug "Total app memory utilisation\t: #{mem_of_total}"
    return score
end

#
#   Main
#

#
#   Check Process health
#

hash_of_processes = Hash.new 
hash_of_bad_processes = Hash.new 
hash_of_processes = get_app_details(options[:application])
hash_of_bad_processes = check_process_state(hash_of_processes)
scores.processes = score_calc_process_numbers(hash_of_bad_processes, options[:processes])
scores.process_state = score_calc_process(hash_of_bad_processes) 
$log.info "Process_state score = #{scores.process_state}"
$log.info "Processes score = #{scores.processes}"


#
#   Check system health
#

#   Check Disks
hash_of_disks = Hash.new 
hash_of_disks = get_disks()
hash_of_disks = check_disk_utilisation(hash_of_disks,options[:disk_utilisation])
scores.disk_utilisation = score_calc_disk_utilisation(hash_of_disks)
$log.info "Disk utilisation score = #{scores.disk_utilisation}"

#   Check memory
hash_of_memory = Hash.new
hash_of_memory = get_system_memory()
scores.memory = score_calc_memory(hash_of_memory,options[:physical_over_alloc],options[:swap_over_alloc],options[:total_over_alloc])
$log.info "Memory utilisation score = #{scores.memory}"

#   Check app memory

# hash of processes contains the info from get_app_details
hash_of_app_memory = Hash.new
hash_of_app_memory = check_app_memory(hash_of_processes)
scores.application = score_calc_app_memory(hash_of_app_memory,options[:application_mem_utilisation]) 
$log.info "Application Memory utilisation score = #{scores.application}"
