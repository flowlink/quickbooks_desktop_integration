class QuickbooksDesktopHelper
  class << self
    def format_batch_response(records, kind = 'success')
      result_group = records.group_by { |n| n['result'] }

      if !result_group.empty? && result_kind = result_group[kind]
        batch = {}

        result_kind.group_by { |n| n['summary'] }.each do |message, records|
          batch[message] = records.map { |r| r['object_ref'] }
        end

        batch
      end
    end
  end
end
