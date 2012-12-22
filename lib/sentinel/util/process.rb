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
# This class will manage processes
#

class Process

    def get_process_details(application)

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

    def check_process_state(processes)

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
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "SN"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is a low-priority process"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "S<s"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is a high-priority session leader"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "Ss+"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is a session leader running in the foreground"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "Ssl"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is a session leader and multi-threaded"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "S<sl"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep and is a session leader, multi-threaded and high-priority"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "Ss"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is a session leader"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "S+"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is in the foreground"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "S<"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state with high-priority"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "Sl"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard sleep state and is multi-threaded"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "R"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard running state"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "R+"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard running state and is in the foreground"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "D"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a uninterruptible sleep state"
                        processes[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "D+"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a uninterruptible sleep state and is in the foreground"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "T"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard stopped state"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "W"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a standard paging state"
                        bad_pids[keys[key]] = {"bad"=>false,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "X"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a pretty bad way, it is Dead!"
                        bad_pids[keys[key]] = {"bad"=>true,"pid"=>processes[keys[key]]["pid"].to_i}
                    when "Z"
                        $log.debug "Process: #{processes[keys[key]]["pid"]} is in a pretty bad way, it's a Zombie!!"
                        bad_pids[keys[key]] = {"bad"=>true,"pid"=>processes[keys[key]]["pid"].to_i}
                    else
                        $log.error "Process: #{processes[keys[key]]["pid"]} is in an unknown state of '#{processes[keys[key]]["state"]}'" 
                        bad_pids[keys[key]] = {"bad"=>true,"pid"=>processes[keys[key]]["pid"].to_i}
                end
            end
            
            #For each bad pid add a score
            
            return bad_pids
        # Probably need to check the state of the PPID as well
    end
    
    def action_process_state (bad_pids)
       # Loop through all pids, take un-relenting action on the bad pids
       keys    = bad_pids.keys
        for key in 0...keys.length
            if (bad_pids[keys[key]]["bad"] == true)
                $log.warn "Killing Process ID \t: #{bad_pids[keys[key]]["pid"]}"
                action_kill_process (bad_pids[keys[key]]["pid"])
            end
        end
    end

    def action_kill_process (pid)
        #This was adapted from: http://ablogaboutcode.com/2010/12/18/a-simple-ruby-script-to-gracefully-terminate-system-processes/
        begin
            Process.kill("TERM",pid)
            Timeout::timeout(30) do
                begin
                    sleep 1
                end while !!(`ps -p #{pid}`.match pid.to_s)
            end
        rescue Timeout::Error
            Process.kill("KILL",pid)
        end
    end
end
