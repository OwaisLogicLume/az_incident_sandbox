#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the Runner target
target = project.targets.find { |t| t.name == 'Runner' }

# Get the Runner group
runner_group = project.main_group.find_subpath('Runner', true)

# Check if GoogleService-Info.plist already exists in project
existing_file = runner_group.files.find { |f| f.path == 'GoogleService-Info.plist' }

if existing_file.nil?
  # Add the file reference
  file_ref = runner_group.new_reference('GoogleService-Info.plist')

  # Add to the target's resources build phase
  target.resources_build_phase.add_file_reference(file_ref)

  puts "✅ GoogleService-Info.plist added to Xcode project"
else
  puts "⚠️  GoogleService-Info.plist already exists in project"
end

# Save the project
project.save

puts "✅ Project saved successfully"
