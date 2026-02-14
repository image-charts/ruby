# coding: utf-8

# https://guides.rubygems.org/specification-reference/#summary
Gem::Specification.new do |spec|
  spec.name          = 'image-charts'
  spec.version="6.1.10"
  spec.authors       = ['Francois-Guillaume Ribreau']
  spec.email         = ['github@fgribreau.com']

  spec.summary       = 'Official Image-Charts.com API client library'
  spec.description   = 'Generate static image charts and embed them into emails, pdf reports, blog posts...'
  spec.homepage      = 'https://www.image-charts.com'
  spec.license       = 'MIT'

  spec.files         = ['./image-charts.rb']
  spec.require_paths = ['.']
  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/image-charts/ruby/issues",
    "documentation_uri" => "https://github.com/image-charts/ruby/README.md",
    "homepage_uri"      => "https://www.image-charts.com",
    "source_code_uri"   => "https://github.com/image-charts/ruby/"
  }
  spec.add_development_dependency 'minitest', '~>5.25'
end
