environment ENV.fetch('RACK_ENV', 'development')
port ENV.fetch('PORT', 5000)
preload_app!
threads_count = Integer(ENV.fetch('MAX_THREADS', '5'))
threads threads_count, threads_count
workers 1
