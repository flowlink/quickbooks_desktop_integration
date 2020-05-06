module Persistence
  # Path for S3 storage
  class Path
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def bucket_name
      'quickbooks-desktop-integration'
    end

    def two_phase_pending
      "#{@config[:origin]}_two_phase_pending"
    end

    def sessions
      "#{@config[:origin]}_sessions"
    end

    def base_name_w_bucket
      "#{bucket_name}/#{@config[:connection_id]}"
    end

    def base_name
      "#{@config[:connection_id]}"
    end

    def qb_pending
      'quickbooks_pending'
    end

    def pending
      "#{@config[:origin]}_pending"
    end

    def in_progress
      "#{@config[:origin]}_in_progress"
    end

    def ready
      "#{@config[:origin]}_ready"
    end

    def processed
      "#{@config[:origin]}_processed"
    end

    def failed
      "#{@config[:origin]}_failed"
    end

    def base_and_ready
      "#{base_name}/#{ready}"
    end

    def base_and_bucket_with_ready
      "#{base_name_w_bucket}/#{ready}"
    end
  end
end
