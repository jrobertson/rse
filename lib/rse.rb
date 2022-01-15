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
                  debug: false, loghost: nil, logport: '9090', log: nil,
                  reghost: nil, spshost: nil, app_rsf: nil)

      @host, @port, @debug = host, port, debug

      puts 'before spspublog'.info if @debug

      log2 = if log then
        log
      elsif loghost
        SPSPubLogDRbClient.new(host: loghost, port: logport)
      end

      puts 'before reg'.info if @debug
      reg = reghost ? RemoteDwsRegistry.new(domain: reghost) : nil

      @rs = rs = RSFServices.new reg, package_basepath: package_basepath,
          log: log2, app_rsf: app_rsf, debug: debug

      @rs.services['sps'] = SPSPub.new(host: spshost) if spshost

      puts 'ready'

    end

    def start()
      puts 'starting ...'
      puts "druby://#{@host.to_s}:#{@port}"

      DRb.start_service "druby://" + @host.to_s + ':' + @port, @rs
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

    # job_filter (which is optional) expects a block
    #
    def initialize(serversx=[], servers: serversx, log: nil, jobfilter: nil )

      DRb.start_service

      @servers = servers.map do |x|

        host, port = x.is_a?(Hash) ? [x[:host], x[:port]] : x

      end

      @log = Logger.new log, 'daily' if log

      @rse = nil
      @jobfilter = jobfilter

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

      if @log then
        @log.info "package: %s, job: %s, params: %s, args: %s" % [package, job, params, args]
      end

      #we pass in the job to determine the server
      fetch_server(job) do |rse|
        rse.run_job package, job, params, *args
      end

    end

    def fetch_server(job=nil)

      host, port = nil, nil

      exit if @servers.empty?

      # using a job filter we can send a job (by checking its name) to
      # a specific server
      #
      r = @jobfilter.call(job) if job and @jobfilter.is_a? Proc

      server = if r then
        r
      else
        @log.info 'job: ' + job.inspect if @log
        @servers.first
      end

      puts 'server: ' + server.inspect

      begin
        host, port = server
        @rse = DRbObject.new_with_uri("druby://#{host}:#{port}")

        yield(@rse) if block_given?

      rescue

        @servers.shift unless port.to_i > 61005
        @rse = nil
        puts ($!).inspect
        @log.warn "server #{host}:#{port} #{($!).inspect}" if @log
        #sleep 1
        #jr20210725 retry


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
                   spshost: 'sps.home', jobfilter: nil)

      @host, @port, @servers, @log = host, port, servers, log
      @spshost = spshost
      @jobfilter = jobfilter

    end

    def start()

      DRb.start_service "druby://#{@host}:#{@port}",
          PassThru.new(@servers, log: @log, jobfilter: @jobfilter)
      DRb.thread.join

    end
  end

end
