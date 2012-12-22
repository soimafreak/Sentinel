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

# Requires
require 'rubygems'
require 'net/http'
require 'uri'
require 'timeout'
$:.unshift File.expand_path("../", __FILE__)
require 'sentinel/scores'
require 'sentinel/cli_options'
require 'sentinel/logging'
require 'sentinel/util/processutil'

class Sentinel

    def initialize()
        # Setting Up Logging
        Logging::new('sentinel','/Users/soimafreak/')
        #Default level is info and No standard out
        Logging.log_level("INFO",false)
        $log.info "Sentinel is starting"

        @scores = Scores.new
        @options = CLIOptions.new
        @proc = ProcessUtil.new
    end   

    def get_app_details ()
        return @proc.get_process_details(@options[:application] )
    end

    #
    #   Get status of pid
    #

    def check_process_state (processes)
        return @proc.check_process_state(processes)
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
        @scores.processes=score
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
        @scores.process_state=score.to_i
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
        @score.disk_utilidation=score.to.i
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

    def check_disk_utilisation(disks)
        utilization = @options[:disk_utilisation]

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

    def check_url (term, uri)
        # Search url for string
        url = URI.parse(uri)
        result = Net::HTTP.get(url)
        match = 0
        regexp = Regexp.new(term)
        if (regexp.match(result) != nil)
            match=1
        end
        
        $log.debug "Check URL String match \t: #{match}" 
        return match
    end

    def score_calc_memory (memory)
        physical_over_alloc=@options[:physical_over_alloc]
        swap_over_alloc=@options[:swap_over_alloc]
        total_over_alloc=@options[:total_over_alloc]
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
        @score.memory=score
    end

    def score_calc_app_memory (app_memory)
        app_mem_utilisation=@options[:application_mem_utilisation]
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
        @score.application=score
    end

    def score_app_url ()
        search_term=@options[:application_search_term]
        uri=@options[:application_url_check]
        result = check_url(search_term, uri)
        score = 0
        if (result == 0)
            score = 100
        end
        @score.application_url=score
    end

    def get_score_processes()
        return @score.processes
    end

    def get_score_process_state()
        return @score.process_state
    end
    
    def get_score_disk_utilisation()
        return @score.disk_utilisation
    end

    def get_score_memory()
        return @score.memory
    end

    def get_score_application()
        return @score.application
    end

    def get_score_application_url()
        return @score.application_url
    end

end
