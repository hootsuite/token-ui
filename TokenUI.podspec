Pod::Spec.new do |s|
  s.name         = "TokenUI"
  s.version      = "5.0"
  s.ios.deployment_target = "11.0"
  s.summary      = "TokenUI is a swift Framework for creating and managing a text input component that allows to add 'tokens' rendered as pills."
  s.homepage     = "https://github.com/hootsuite/TokenUI"
  s.license      = { :type => "Apache", :file => "LICENSE.md" }
  s.author       = { "Hootsuite Media" => "opensource@hootsuite.com" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/hootsuite/TokenUI.git", :tag => "v#{s.version}" }
  s.source_files = "TokenUI"
  s.resource     = "TokenUI/**/*.{xib,xcassets}"
  s.weak_framework = "XCTest"
  s.requires_arc = true
end
