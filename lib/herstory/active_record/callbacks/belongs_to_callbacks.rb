module Herstory
  class BelongsToCallbacks
    def initialize(reflection:, superordinate:)
      @reflection = reflection
      @association_name = reflection.name
      @reflected_class = reflection.class_name.constantize unless reflection.polymorphic?
      @superordinate = superordinate
    end

    def after_save(record)
      return unless record.saved_changes.include?("#{@association_name}_id")

      record_id_was, record_id_is = record.saved_changes["#{@association_name}_id"]

      # There is no reflected class on polymorphic
      if @reflection.polymorphic?

        # So we check if a record was previously assigned
        record_klass_name_was, record_klass_name_is = record.saved_changes["#{@association_name}_type"]

        # And if it was, we find it
        if record_klass_name_was
          record_klass_was = record_klass_name_was.constantize
          record_was = record_klass_was.find_by_id(record_id_was)
        end

        if record_klass_name_is
          record_klass_is = record_klass_name_is.constantize
          record_is = record_klass_is.find_by_id(record_id_is)
        end

      else
        # On non-polymorphic associations, we know which class
        # is on the other side of the association
        record_was = @reflection.klass.find_by_id(record_id_was)
        record_is = @reflection.klass.find_by_id(record_id_is)
      end

      record.log_record_change(record_was, record_is, @superordinate)
    end
  end
end
