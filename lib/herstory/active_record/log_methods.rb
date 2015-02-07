module Herstory
  def log_record_change(old_record, new_record, association_superordinate)
    ChangeLogger.log_association_change(
      :deletion, self, association_superordinate, old_record, false, Thread.current[:current_user]
    ) if old_record

    ChangeLogger.log_association_change(
      :addition, self, association_superordinate, new_record, false, Thread.current[:current_user]
    ) if new_record
  end

  
end
