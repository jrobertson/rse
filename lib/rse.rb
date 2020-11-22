#!/usr/bin/env ruby

# file: rse.rb


require 'drb'
require 'sps-pub'
require 'sps-sub'    
require 'rsf_services'
require 'remote_dwsregistry'
require 'spspublog_drb_client'


module Rse
  
  class Server
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
      
      @rs.services['sps'] = SPSPub.new(host: spshost) if spshost
      
      puts 'ready'

    end

    def start()
      puts 'starting ...'
      puts "druby://#{@host}:#{@port}"
      DRb.start_service "druby://#{@host}:#{@port}", @rs
      DRb.thread.join

    end
  end
  
  class Subscriber < SPSSub
    
    def initialize(host: 'rse.home', spshost: 'sps.home')
      
      @rsc = RSC.new(host)
      super(host: spshost)

    end
    
    def subscribe(topic: 'rse/#')
      
      super(topic: topic) do |msg, topic|
      
        a = topic.split('/')[1..-1]
        
        if a.length < 2 then
          
          begin
            r = @rsc.run_job(a.first, msg)
          rescue
            self.notice 'rse_result: no job ' + a.first
          end
          
          self.notice 'rse_result: ' + r.inspect
          
        else
          
          package, job = a

          begin
            r = @rsc.run_job(package, job, {}, msg)
          rescue
            self.notice 'rse_result: no job ' + a.first
          end
          
          self.notice "rse_result/%s/%s: %s" % [package, job, r.inspect ]
        end
        
      end
    end  
    
  end  

end


module RseProxy
    
  class PassThru

    def initialize(serversx=[], servers: serversx, log: nil )
      
      DRb.start_service
      
      @servers = servers.map do |x|
        
        host, port = x.is_a?(Hash) ? [x[:host], x[:port]] : x        
        
      end
      
      @log = Logger.new log, 'daily' if log
      
    end

    def delete()
      fetch_server() { |rse| rse.delete }
    end
                     
    def get()
      fetch_server() { |rse| rse.get }
    end
                     
    def put()
      fetch_server() { |rse| rse.put }
    end
                     
    def post()
      fetch_server() { |rse| rse.post }
    end
      
    def package_methods(name)
      fetch_server() { |rse| rse.package_methods(name) }
    end
      
    def run_job(package, job, params={}, *args)
      
      @log.info "package: %s, job: %s, params: %s, args: %s" \
          % [package, job, params, args] if @log
      
      fetch_server() { |rse| rse.run_job package, job, params, *args    }
      
    end
    
    def fetch_server()
      
      begin
        
        servers = @servers.clone
          
        server = servers.shift
        host, port = server
        rse = DRbObject.new_with_uri("druby://#{host}:#{port}")    
        yield(rse) if block_given?
        
      rescue
        
        puts ($!).inspect
        @log.warn "server #{host}:#{port} down" if @log
        retry if servers.any?        
        
      end
      
    end

    def type()
      fetch_server() { |rse| rse.type }
    end
    
    def type=(s)
      fetch_server() { |rse| rse.type=(s) }
    end
    
    private
  
    def method_missing(method_name, *args)    
      fetch_server() { |rse| rse.get.method(method_name).call(*args) }
    end    
      
    
  end

  class Server
    
    def initialize(host: 'rse.home', port: '61000', servers: [], log: nil, 
                   spshost: 'sps.home')
      
      @host, @port, @servers, @log = host, port, servers, log
      @spshost = spshost
      
    end
    
    def start()
      
      DRb.start_service "druby://#{@host}:#{@port}", 
          PassThru.new(@servers, log: @log)
      DRb.thread.join      
      
    end
  end
  
end


