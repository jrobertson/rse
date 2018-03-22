#!/usr/bin/env ruby

# file: rse.rb


require 'drb'
require 'sps-sub'    
require 'rsf_services'
require 'remote_dwsregistry'
require 'spspublog_drb_client'



class Rse
  
  def initialize(package_basepath=nil, host: '', port: '61000', 
                 debug: false, loghost: 'localhost', reghost: 'localhost', 
                 spshost: 'localhost')

    @host, @port, @debug = host, port, debug

    log = SPSPubLogDRbClient.new host: loghost        
    reg = RemoteDwsRegistry.new domain: reghost   

    @rs = rs = RSFServices.new reg, 
        package_basepath: package_basepath, log: log
    
    sps = SPSSub.new host: spshost
       
    Thread.new do
      sps.subscribe(topic: 'rse/#') do |msg,topic|
        a = topic.split('/')[1..-1]
        if a.length < 2 then
          begin
            r = rs.run_job(a.first, msg)
          rescue
            sps.notice 'rse_result: no job ' + a.first
          end
          sps.notice 'rse_result: ' + r.inspect
        else
          package, job = a
          begin
            r = rs.run_job(package, job, {}, msg)
           rescue
            sps.notice 'rse_result: no job ' + a.first
           end
          sps.notice "rse_result/%s/%s: %s" % [package, job, r.inspect ]
        end
      end
    end

    @rs.services['sps'] = sps

    puts 'ready'

  end

  def start()
    puts 'starting ...'
    DRb.start_service "druby://#{@host}:#{@port}", @rs
    DRb.thread.join

  end
end
