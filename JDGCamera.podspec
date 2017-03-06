Pod::Spec.new do |s|

  s.name         = "JDGCamera"
  s.version      = "1.0"
  s.summary      = "JDGCamera is a simple camera created with LLSimpleCamera to capture image and record video with maximum recording duration."

  s.description  = <<-DESC

JDGCamera is a simple camera created with LLSimpleCamera to capture image and record video with maximum recording duration

                   DESC

  s.homepage     = "https://github.com/jefrydagucci/JDGCamera"

  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }

  s.author             = { "Jefry" => "jefrydagucci@gmail.com" }

  s.platform     = :ios, "8.0"
  s.source       = { :git => "http://EXAMPLE/JDGCamera.git", :tag => "#{s.version}" }

  s.source_files  = "Sources", "Sources/**/*.{swift}"

  s.framework  = "AVFoundation"

  s.requires_arc = true

  s.dependency "LLSimpleCamera", "~> 5.0"
  s.dependency "IoniconsSwift", "~> 2.1.4"
  s.dependency "UIImage+Additions", "~> 2.1.3"
  s.dependency "SDRecordButton", "~> 1.0"

end
