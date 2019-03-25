Gem::Specification.new do |s|
  s.name = 'rse'
  s.version = '0.2.0'
  s.summary = 'Executes Ruby jobs (using the rsf_services gem) from ' + 
      'a DRb server.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/rse.rb']
  s.add_runtime_dependency('sps-sub', '~> 0.3', '>=0.3.7')
  s.add_runtime_dependency('rsf_services', '~> 0.8', '>=0.8.0')
  s.add_runtime_dependency('remote_dwsregistry', '~> 0.4', '>=0.4.1')
  s.add_runtime_dependency('spspublog_drb_client', '~> 0.1', '>=0.1.1')
  s.signing_key = '../privatekeys/rse.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/rse'
end
