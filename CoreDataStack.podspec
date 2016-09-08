Pod::Spec.new do |s|
  s.name         = "CoreDataStack"
  s.version      = "0.1.0"
  s.summary      = "Core data stack for Swift"
  s.description  = <<-DESC
                     Core data stack for Swift
                     * NSManagedObject extensions methods for creating, querying and deleting managed objects
                     * Managed object change observer
                   DESC
  s.documentation_url = 'https://github.com/larsblumberg/core-data-stack'
  s.homepage     = "https://github.com/larsblumberg/core-data-stack"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Lars Blumberg" => "lars.blumberg@posteo.de" }
  s.social_media_url   = "http://twitter.com/larsblumberg"

  s.ios.deployment_target  = "8.0"
  s.osx.deployment_target  = "10.9"
  s.tvos.deployment_target = "9.0"

  s.framework    = 'CoreData'

  s.source       = { :git => "https://github.com/larsblumberg/core-data-stack.git", :branch => "master" }
  s.source_files = "Source/*.swift"
end
