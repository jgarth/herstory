module Herstory
  class HasManyThroughCallbacks
    def initialize(record:, reflection:, superordinate:)

      @first_association_klass = record
      @first_association_name = record.model_name.element # FIXME: This is a guess that only works sometimes

      @second_association_klass = reflection.klass
      @second_association_name = reflection.klass.model_name.element

      @superordinate = superordinate
    end

    def after_save(record)
      return unless record.valid?

      if record.saved_changes.include?("#{@first_association_name}_id") &&
        record.saved_changes.include?("#{@second_association_name}_id")

        first_class_was = @first_association_klass.find_by_id(record.send("#{@second_association_name}_id_before_last_save"))
        first_class_is = record.send(@first_association_name)

        second_class_was = @second_association_klass.find_by_id(record.send("#{@second_association_name}_id_before_last_save"))
        second_class_is = record.send(@second_association_name)
      end

      first_class_was.log_record_change(second_class_was, nil, @superordinate) if second_class_was
      first_class_is.log_record_change(nil, second_class_is, @superordinate) if second_class_is
    end

    def before_destroy(record)
      first_class_was = @first_association_klass.find_by_id(record.send("#{@second_association_name}_id_was"))
      first_class_is = record.send(@first_association_name)
      second_class_was = @second_association_klass.find_by_id(record.send("#{@second_association_name}_id_was"))
      second_class_is = record.send(@second_association_name)

      # Only need to call log_record_change once because
      # it will save event for other record as well
      if first_class_was
        first_class_was.log_record_change(second_class_was, nil, @superordinate)
      else
        first_class_is.log_record_change(second_class_was, nil, @superordinate)
      end
    end
  end
end
