module Herstory
  class RecordCallbacks
    def after_save(record)
      return if Thread.current[:skip_logging]

      if record.saved_change_to_id?
        ChangeLogger.log_creation(record, Thread.current[:current_user])
      else
        ChangeLogger.log_attribute_changes(record, Thread.current[:current_user])
      end
    end
  end
end
