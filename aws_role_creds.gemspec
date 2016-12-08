# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "aws_role_creds"
  spec.version       = "0.0.5"
  spec.authors       = ["Jack Thomas"]
  spec.email         = ["jackdavidthomas@gmail.com"]

  spec.description   = %q{Used to fetch multiple AWS Role Credential Keys using different Session Keys}
  spec.summary       = %q{Manage AWS STS credentials with MFA}
  spec.homepage      = "https://github.com/MrPrimate/aws_role_keys"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/aws}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "aws-sdk"
  spec.add_runtime_dependency "inifile"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
