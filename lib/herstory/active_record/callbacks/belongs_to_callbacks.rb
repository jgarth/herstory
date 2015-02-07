module Herstory
  class BelongsToCallbacks
    def initialize(reflection:, superordinate:)
      @reflection = reflection
      @association_name = reflection.name
      @reflected_class = reflection.class_name.constantize unless reflection.polymorphic?
      @superordinate = superordinate
    end

    def before_save(record)
      return unless record.valid?

      # There is no reflected class on polymorphic
      if @reflection.polymorphic?

        # So we check if a record was previously assigned
        record_klass_name_was = record.send("#{@association_name}_type_was")

        # And if it was, we find it
        if record_klass_name_was
          record_klass_was = record_klass_name_was.constantize
          record_was = record_klass_was.find_by_id(record.send("#{@association_name}_id_was"))
        end

      else
        # On non-polymorphic associations, we know which class
        # is on the other side of the association
        record_was = @reflected_class.find_by_id(record.send("#{@association_name}_id_was"))
      end

      record_is = record.send(@association_name)

      record.log_record_change(record_was, record_is, @superordinate)
    end
  end
end
