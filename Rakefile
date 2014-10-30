$stdout.sync = true

desc 'Open pry console'
task :console do
  require 'pry'

  env_file = File.join File.expand_path('..', __FILE__), '.env'

  if File.exist? env_file
    # require 'dotenv'
    # Dotenv.load
  end

  def client
    @client
  end

  ARGV.clear
  Pry.start
end

