Pod::Spec.new do |s|
  s.name             = "Droste"
  s.version          = "0.1.0"
  s.summary          = "A short description of Droste."
  s.homepage         = "https://github.com/gtsifrikas/Droste"
  s.license          = { type: 'MIT', file: 'LICENSE' }
  s.author           = { "George Tsifrikas" => "gtsifrikas@gmail.com" }
  s.source           = { git: "https://github.com/gtsifrikas/Droste.git", tag: s.version.to_s }
  s.social_media_url = 'https://twitter.com/gtsifrikas'
  s.ios.deployment_target = '9.0'
  s.requires_arc = true
  s.source_files = 'Sources/**/*.{swift,h,m}'
  s.module_name = 'Droste'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.dependency 'RxSwift', '~> 3.0'

  s.test_spec 'Tests' do |t|
    t.source_files = 'Tests/*.swift', 'Sources/Extensions.swift'
    t.dependency 'RxSwift', '~> 3.0'
    t.dependency 'Nimble'
    t.dependency 'Quick'
    t.dependency 'RxTest', '~> 3.0'
  end
end