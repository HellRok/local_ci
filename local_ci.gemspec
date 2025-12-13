Gem::Specification.new do |s|
  s.name = "local_ci"
  s.version = "0.0.4"
  s.summary = "Run CI locally"
  s.description = "A way to run CI locally but also able to run easily on your hosted CI"
  s.authors = ["Sean Earle"]
  s.email = "sean.r.earle@gmail.com"
  s.files = `git ls-files`.split($\)
  s.executables = []
  s.homepage = "https://github.com/HellRok/local_ci"
  s.license = "MIT"

  s.add_dependency "logger"
  s.add_dependency "pastel"
  s.add_dependency "rake"
  s.add_dependency "tty-command"
  s.add_dependency "tty-cursor"
  s.add_dependency "tty-screen"
end
