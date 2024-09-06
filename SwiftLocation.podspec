Pod::Spec.new do |s|
    s.name         = "SwiftLocation"
    s.version      = "6.0.0"
    s.summary      = "Location Manager Made Easy"
    s.description  = <<-DESC
    ⚓️ Async/Await CLLocationManager Wrapper for Apple Platforms
    DESC
    s.homepage     = "https://github.com/malcommac/SwiftLocation.git"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author             = { "Daniele Margutti" => "hello@danielemargutti.com" }
    s.social_media_url   = "https://twitter.com/danielemargutti"
    s.ios.deployment_target = "14.0"
    s.macos.deployment_target = "11.0"
    s.watchos.deployment_target = "7.0"
    s.tvos.deployment_target = "14.0"
    s.source       = { :git => "https://github.com/malcommac/SwiftLocation.git", :tag => s.version.to_s }
    s.frameworks  = "Foundation","CoreLocation","MapKit"
    s.swift_versions = ['5.0', '5.1', '5.3']
  
    s.subspec 'Core' do |s|
      s.source_files = "Sources/SwiftLocation/**/*.swift"
      s.frameworks  = "Foundation","CoreLocation","MapKit"
    end
  end