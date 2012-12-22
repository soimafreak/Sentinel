#
#   Set up Logging
#

require 'rubygems'
require 'log4r'

class Logging

  def initialize(log_name,log_location="/var/log/")
    # Create a logger named 'log' that logs to stdout
    $log = Log4r::Logger.new log_name

    # Open a new file logger and ask him not to truncate the file before opening.
    # FileOutputter.new(nameofoutputter, Hash containing(filename, trunc))
    file = Log4r::FileOutputter.new('fileOutputter', :filename => "#{log_location}#{log_name}.log",:trunc => false)

    # You can add as many outputters you want. You can add them using reference
    # or by name specified while creating
    $log.add(file)
    # or mylog.add(fileOutputter) : name we have given.

    # As I have set my logging level to ERROR. only messages greater than or 
    # equal to this level will show. Order is
    # DEBUG < INFO < WARN < ERROR < FATAL

    # specify the format for the message.
    format = Log4r::PatternFormatter.new(:pattern => "[%l] %d: %m")

    # Add formatter to outputter not to logger. 
    # So its like this : you add outputter to logger, and add formattters to outputters.
    # As we haven't added this formatter to outputter we created to log messages at 
    # STDOUT. Log messages at stdout will be simple
    # but the log messages in file will be formatted
    file.formatter = format
    
  end

  def self.log_level(lvl,verbose=false)
    # You can use any Outputter here.
    $log.outputters = Log4r::Outputter.stdout if verbose

    # Log level order is DEBUG < INFO < WARN < ERROR < FATAL
    case lvl
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
             print "You provided an invalid option: #{lvl}"
    end
  end

end

