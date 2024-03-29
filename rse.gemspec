Gem::Specification.new do |s|
  s.name = 'rse'
  s.version = '0.4.1'
  s.summary = 'Executes Ruby jobs (using the rsf_services gem) from ' + 
      'a DRb server.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/rse.rb']
  s.add_runtime_dependency('sps-pub', '~> 0.5', '>=0.5.5')
  s.add_runtime_dependency('sps-sub', '~> 0.3', '>=0.3.7')
  s.add_runtime_dependency('rsf_services', '~> 0.9', '>=0.9.5')
  s.add_runtime_dependency('remote_dwsregistry', '~> 0.4', '>=0.4.1')
  s.add_runtime_dependency('spspublog_drb_client', '~> 0.2', '>=0.2.1')
  s.signing_key = '../privatekeys/rse.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/rse'
end
