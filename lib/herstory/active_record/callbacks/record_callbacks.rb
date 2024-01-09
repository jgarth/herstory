# frozen_string_literal: true

module Herstory
  class RecordCallbacks
    def initialize(options)
      @options = options
    end

    def after_save(record)
      return if Thread.current[:skip_logging]

      if record.saved_change_to_id
        if @options[:log_all_attributes_on_creation]
          ChangeLogger.log_all_attributes_on_creation(record, Thread.current[:current_user])
        else
          ChangeLogger.log_creation(record, Thread.current[:current_user])
        end
      else
        ChangeLogger.log_attribute_changes(record, Thread.current[:current_user])
      end
    end
  end
end
