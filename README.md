# Introducing the Rse gem

The Rse gem runs a DRb service to run RSF jobs upon request from any DRb client.

## Usage

    require 'rse'

    Rse.new('http://a0.jamesrobertson.eu/qbx/r/dandelion_a3').start

In the above example the path *.../dandelion_a3* is a file directory containing executable RSF files.

## Additinal options

    require 'rse'

    rse = Rse.new 'http://a0.jamesrobertson.eu/qbx/r/dandelion_a3', host: 'rse.home', spshost: 'sps.home', reghost: 'reg.home', loghost: 'spslog.home',  debug: true

In the above example the Rse service can also contain other services which might be used by an RSF job including the following:

* sps: SimplePubSub publisher
* reg: XML Registry client
* spslog: SPSlog client, useful for debugging RSF jobs

## Resources

* rse https://rubygems.org/gems/rse

rsf rse
