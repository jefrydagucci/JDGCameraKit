Pod::Spec.new do |s|

  s.name         = "JDGCameraKit"
  s.version      = "1.0"
  s.summary      = "JDGCameraKit is a simple camera created with LLSimpleCamera to capture image and record video with maximum recording duration."

  s.description  = <<-DESC

JDGCamera is a simple camera created with LLSimpleCamera to capture image and record video with maximum recording duration like Instagram story camera

                   DESC

  s.homepage     = "https://github.com/jefrydagucci/JDGCamera"

  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }

  s.author             = { "Jefry" => "jefrydagucci@gmail.com" }

  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/jefrydagucci/JDGCamera.git", :tag => "v#{s.version}" }
  s.social_media_url = "http://instagram.com/jefrydagucci"

  s.source_files  = "Sources/*.{swift}"

  s.framework  = "AVFoundation"

  s.requires_arc = true

  s.dependency "LLSimpleCamera", "~> 5.0"
  s.dependency "IoniconsSwift", "~> 2.1.4"
  s.dependency "UIImage+Additions", "~> 2.1.3"
  s.dependency "SDRecordButton", "~> 1.0"

end
