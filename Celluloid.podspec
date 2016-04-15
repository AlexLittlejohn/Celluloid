Pod::Spec.new do |spec|
  spec.name               = "Celluloid"
  spec.version            = "0.1.0"
  spec.summary            = "A view that allows you to control many aspects of the iOS camera."
  spec.source             = { :git => "https://github.com/AlexLittlejohn/Celluloid.git", :tag => spec.version.to_s }
  spec.requires_arc       = true
  spec.platform           = :ios, "8.0"
  spec.license            = "MIT"
  spec.source_files       = "Celluloid/**/*.{swift}"
  spec.homepage           = "https://github.com/AlexLittlejohn/Celluloid"
  spec.author             = { "Alex Littlejohn" => "alexlittlejohn@me.com" }
end
