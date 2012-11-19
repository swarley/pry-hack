task :test do
  Dir.glob(File.expand_path("../t/", __FILE__) + "/test_*").each do |file|
    sh "bacon #{file}"
  end
end

task :build do
  sh "gem build pry-hack.gemspec"
end

task :release do
  sh "gem push #{Dir.glob("pry-hack-*.gem").last}"
end
