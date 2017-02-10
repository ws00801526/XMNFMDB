Pod::Spec.new do |s|
  s.name         = 'XMNFMDB'
  s.summary      = '基于FMDB,YYModel封装的一键增删改查sqlite数据库功能'
  s.version      = '0.0.1'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { 'XMFraker' => '3057600441@qq.com' }
  s.homepage     = 'https://github.com/ibireme/YYModel'
  s.source       = { :git => './', :tag => s.version.to_s }
  
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.source_files = 'XMNFMDB/*.{h,m}'
  s.public_header_files = 'XMNFMDB/*.{h}'
  
  s.frameworks = 'Foundation', 'CoreFoundation'
  s.dependency 'YYModel' 
  s.dependency 'FMDB'
  s.libraries = 'sqlite3'
end
