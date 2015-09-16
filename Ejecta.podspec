Pod::Spec.new do |s|
  s.name = 'Ejecta'
  s.version = '1.5'
  s.license = 'MIT'
  s.summary = 'A Fast, Open Source JavaScript, Canvas & Audio Implementation for iOS.'
  s.homepage = 'http://impactjs.com/ejecta'
  s.author = { 'Dominic Szablewski' => 'dominic.szablewski@gmail.com' }
  s.source = { :git => 'https://github.com/fmezas/Ejecta.git', :commit => 'fa035d0' }
  s.description = 'A Fast, Open Source JavaScript, Canvas & Audio Implementation for iOS.'
  s.platform = :ios
  s.requires_arc = false
  
  s.source_files = 'Source/Ejecta/**/*.{h,m,mm}'
  s.resources    = 'Source/Ejecta/ejecta.js', 'Source/Ejecta/EJCanvas/2D/Shaders/*'
  
  s.default_subspecs = 'JavaScriptCore', 'SocketRocket'
  s.frameworks = 'JavaScriptCore', 'SystemConfiguration', 'CoreText', 'QuartzCore', 'GameKit', 'CoreGraphics', 'OpenAL', 'AudioToolbox', 'OpenGLES', 'AVFoundation', 'iAd', 'CoreMotion', 'MediaPlayer', 'CoreLocation'
  
  s.header_mappings_dir =  'Source/Ejecta'
  
  s.subspec 'SocketRocket' do |os|
    os.source_files = 'Source/lib/SocketRocket/*.{h,m}'
    os.requires_arc = true
  end

  s.subspec 'JavaScriptCore' do |os|
    os.source_files = 'Source/lib/JavaScriptCore.framework/Versions/A/Headers/*.h'
    os.preserve_paths = 'Source/lib/JavaScriptCore.framework/*'
    os.library = 'stdc++', 'icucore'
    os.xcconfig = { 
      'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/Ejecta/Source/lib"', 
      'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/Ejecta/Source/lib"', 
      'FRAMEWORK_SEARCH_PATHS' => '"$(PODS_ROOT)/Ejecta/Source/lib"'
    }
    
    os.header_mappings_dir = 'Source/Ejecta'
    
    s.xcconfig = {
      'CLANG_CXX_LANGUAGE_STANDARD' => 'gnu++98',
      'CLANG_CXX_LIBRARY' => 'libc++'
    }
  end
end
