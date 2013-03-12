#!/usr/bin/env ruby

require 'socket'
require 'cgi'

server = TCPServer.new('127.0.0.1', 8888)
home_path = Dir.getwd #Get home path

puts 'Listening on 127.0.0.1:8888'
loop {
  begin
    client = server.accept
    first_request_header = client.gets

    #Get path requested
    url = first_request_header.split()[1] #End of url requested
    url_path, sort = url.split('?') #Break into url and sort method

    path = url_path.split('/') #Break into successive directories
    path.shift #Remove first empty string before \

    #Navigate as far down requested path as possible
    Dir.chdir(home_path) #Go back to home path
    path.each {
      |dirname|
      if File.directory?(dirname)
        Dir.chdir(dirname)
      else break
      end
    }
    
    
    #Get current relative path
    rel_path = Dir.getwd
    rel_path.slice!(home_path)

    #Start HTML table
    resp = '<table border = "1">'
    #Filename: Default sort
    resp += '<tr><td><a href="' + rel_path + '?name">File name</a></td>'
    #Other sorts
    resp += '<td><a href="' + rel_path + '?size">Size (bytes)</a></td>'
    resp += '<td><a href="' + rel_path + '?date">Date Modified</a></td></tr>'

    #Add files in current directory to array [[fname, size, date]...]
    files = []
    Dir.foreach ('.') {
      |filename|
      
      size = File.size(filename)
      mod_time = File.stat(filename).mtime
      files.push([filename, size, mod_time])
    }

    #Sort array if necessary (name-sorted by default)
    if not sort.nil?
      if sort == 'size'
        files = files.sort_by {|file| file[1]}
        puts files
      elsif sort == 'date'
        files = files.sort_by {|file| file[2]}
      end
    end

    #Add files to HTML table
    files.each {
      |filedata|
      filename, size, mod_time = filedata

      #Make file a link if it's a directory
      if File.directory?(filename)
        #Add directory name
        dirpath = rel_path + "/" + filename
        #Make link
        filetxt = '<a href="' + dirpath + '">'
        filetxt += filename + '</a>'
      else
        filetxt = filename
      end

      #Construct row of table
      resp += "<tr><td>" + filetxt + "</td>"
      resp += "<td>" + size.to_s + "</td>"
      resp += "<td>" + mod_time.asctime + "</td>"
      resp += "</tr>"
    }
    resp += "</table>"
    
    #Make headers
    headers = ['http/1.1 200 ok',
               "date: #{CGI.rfc1123_date(Time.now)}",
               'server: ruby',
               'content-type: text/html; charset=iso-8859-1',
               "content-length: #{resp.length}\r\n\r\n"].join("\r\n")
    client.puts headers          # send the time to the client
    client.puts resp
    client.close

  #If error, print backtrace and continue operation
  rescue => e
    puts e.message
    puts e.backtrace
  end
}
