#!/usr/bin/env ruby

# file: rse.rb


require 'drb'
require 'sps-sub'    
require 'rsf_services'
require 'remote_dwsregistry'
require 'spspublog_drb_client'


class Rse
  using ColouredText
  
  def initialize(package_basepath=nil, host: '0.0.0.0', port: '61000', 
                 debug: false, loghost: nil, logport: '9090', 
                 reghost: nil, spshost: nil, app_rsf: nil)

    @host, @port, @debug = host, port, debug

    puts 'before spspublog'.info if @debug
    log = loghost ? SPSPubLogDRbClient.new(host: loghost, port: logport) : nil
    
    puts 'before reg'.info if @debug
    reg = reghost ? RemoteDwsRegistry.new(domain: reghost) : nil

    @rs = rs = RSFServices.new reg, package_basepath: package_basepath, 
        log: log, app_rsf: app_rsf, debug: debug
    
    sps = spshost ? SPSSub.new(host: spshost) : nil

    if sps then
        
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
      
    end

    puts 'ready'

  end

  def start()
    puts 'starting ...'
    DRb.start_service "druby://#{@host}:#{@port}", @rs
    DRb.thread.join

  end
end
