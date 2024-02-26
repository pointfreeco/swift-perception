Pod::Spec.new do |s|

  s.name         = "Perception"
  s.version      = "1.1.0"
  s.summary      = "Observable tools, backported."

  s.description  = <<-DESC
  Observation tools for platforms that do not officially support observation.
                   DESC

  s.homepage     = "https://github.com/pointfreeco/swift-perception"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Point-Free" => "https://github.com/pointfreeco" }

  s.ios.deployment_target = "13.0"
  s.tvos.deployment_target = "13.0"
  s.osx.deployment_target = "10.15"
  s.watchos.deployment_target = "6.0"
  s.swift_versions = "5.9"

  s.source       = { :git => "https://github.com/pointfreeco/swift-perception.git", :tag => "#{s.version}" }

  s.dependency 'SwiftyCollections'

  s.source_files = 'Sources/Perception/**/*.swift'

  s.prepare_command = 'swift build -c release && cp -f .build/release/PerceptionMacros ./Binary'

  s.preserve_paths = ["Binary/PerceptionMacros"]
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-load-plugin-executable ${PODS_ROOT}/Perception/Binary/PerceptionMacros#PerceptionMacros'
  }
  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-load-plugin-executable ${PODS_ROOT}/Perception/Binary/PerceptionMacros#PerceptionMacros'
  }

end
