#!/usr/bin/env ruby
require 'xcodeproj'
require 'fileutils'

PROJECT_NAME = 'LifeInWeeks'
BUNDLE_ID    = 'com.shogo.4420life'
SRC_ROOT     = File.expand_path(File.dirname(__FILE__))
PROJ_PATH    = File.join(SRC_ROOT, "#{PROJECT_NAME}.xcodeproj")

FileUtils.rm_rf(PROJ_PATH)
project = Xcodeproj::Project.new(PROJ_PATH)

# --- Main app target ---
target = project.new_target(:application, PROJECT_NAME, :ios, '17.0')
target.build_configurations.each do |config|
  s = config.build_settings
  s['SWIFT_VERSION']                      = '6.0'
  s['TARGETED_DEVICE_FAMILY']             = '1'
  s['INFOPLIST_FILE']                     = 'SupportingFiles/Info.plist'
  s['CODE_SIGN_STYLE']                    = 'Automatic'
  s['DEVELOPMENT_TEAM']                   = ''
  s['SWIFT_EMIT_LOC_STRINGS']             = 'YES'
  s['ENABLE_PREVIEWS']                    = 'YES'
  s['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  s['PRODUCT_BUNDLE_IDENTIFIER']          = config.name == 'Debug' ? "#{BUNDLE_ID}.debug" : BUNDLE_ID
  s['SRCROOT']                            = SRC_ROOT
end

# --- Source files group (all swift files, absolute paths) ---
src_group = project.main_group.new_group(PROJECT_NAME)

source_refs = []
swift_dirs  = %w[App Models Repositories ViewModels Views/Grid Views/WeekDetail Views/Stats Views/Settings Views/Onboarding AppIntents Utilities]

swift_dirs.each do |rel_dir|
  abs_dir   = File.join(SRC_ROOT, rel_dir)
  group     = src_group.new_group(File.basename(rel_dir))
  Dir.glob("#{abs_dir}/*.swift").sort.each do |abs_path|
    ref = group.new_file(abs_path)
    source_refs << ref
  end
end

# SupportingFiles
support_dir = File.join(SRC_ROOT, 'SupportingFiles')
FileUtils.mkdir_p(support_dir)
support_group = src_group.new_group('SupportingFiles')
support_group.new_file(File.join(support_dir, 'Info.plist'))

# Assets.xcassets
assets_path = File.join(SRC_ROOT, 'Assets.xcassets')
assets_ref  = project.main_group.new_file(assets_path)
target.add_resources([assets_ref])

# Add source files to compile phase
source_refs.each { |ref| target.source_build_phase.add_file_reference(ref) }

# --- Test target ---
tests_dir  = File.join(SRC_ROOT, 'Tests')
FileUtils.mkdir_p(tests_dir)
test_target = project.new_target(:unit_test_bundle, "#{PROJECT_NAME}Tests", :ios, '17.0')
test_target.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = '6.0'
  config.build_settings['TEST_HOST']     = "$(BUILT_PRODUCTS_DIR)/#{PROJECT_NAME}.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/#{PROJECT_NAME}"
end
test_target.add_dependency(target)

test_group = project.main_group.new_group("#{PROJECT_NAME}Tests")
Dir.glob("#{tests_dir}/**/*.swift").sort.each do |abs_path|
  ref = test_group.new_file(abs_path)
  test_target.source_build_phase.add_file_reference(ref)
end

project.save
puts "✅ #{PROJ_PATH} を生成しました"
puts "   ファイル数: #{source_refs.size} Swift files"
