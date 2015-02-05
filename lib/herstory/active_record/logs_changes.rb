module LogsChanges
  extend ActiveSupport::Concern

  included do
    include HasEvents

    def self.without_logging(&block)
      begin
        Thread.current[:skip_logging] = true
        yield
      ensure
        Thread.current[:skip_logging] = false
      end
    end

    def log_record_change(old_record, new_record, association_superordinate)
      ChangeLogger.log_association_change(
        :deletion, self, association_superordinate, old_record, false, Thread.current[:current_user]
      ) if old_record

      ChangeLogger.log_association_change(
        :addition, self, association_superordinate, new_record, false, Thread.current[:current_user]
      ) if new_record
    end

    def self.logs_changes(options = {})
      # This part does change logging on the model
      self.class_eval do
        cattr_accessor :_logged_associations do
          []
        end

        after_save -> (record) {
          return if Thread.current[:skip_logging]

          if record.id_changed?
            ChangeLogger.log_creation(record, Thread.current[:current_user])
          else
            ChangeLogger.log_attribute_changes(record, Thread.current[:current_user])
          end
        }
      end

      # This part does change logging on the model's associations
      raise ArgumentError.new("Unknown option :include for log_changes. Did you mean :includes?") if options.has_key? :include

      # Normalize options
      return unless options.is_a? Hash

      associations_with_options = options[:includes] || []

      associations_with_options.flat_map do |included|
          [*included].map{|k,v| [k, v || {}]}
      end.to_h if associations_with_options

      associations_with_options.each do |association_name, association_options|

        if association_options && association_options.has_key?(:superordinate)
          association_superordinate = association_options[:superordinate]
        else
          association_superordinate = :both
        end

        reflection = self.reflect_on_association(association_name)
        # puts "Defining #{self} -> #{association_name} with options #{association_options}"

        raise ArgumentError.new("Unknown association '#{association_name}'") unless reflection

        reflected_class = reflection.class_name.constantize

        if reflection.belongs_to?
          # Check if the other side already registered callbacks
          if reflected_class.logs_changes_for? association_name.to_s.pluralize
            # puts "SKIPPING #{self} -> has_many #{association_name} through: #{join_klass}."
            return
          end

          self.before_save -> (record) {
            break unless record.valid?

            record_was = reflected_class.find_by_id(record.send("#{association_name}_id_was"))
            record_is = record.send(association_name)

            self.log_record_change(record_was, record_is, association_superordinate)

          }, if: "#{association_name}_id_changed?"
        elsif reflection.collection? && reflection.through_reflection
          # Go for join model's belongs_to assocs instead

          # Step 1: find join model
          join_klass = reflection.through_reflection.klass

          # Step 2: remember which associations to save on
          first_association_klass = self

          # FIXME: This is a guess that only works for CHICARGO
          first_association_name = self.model_name.element

          second_association_klass = reflection.klass
          second_association_name = reflection.klass.model_name.element

          # Check if the other side already registered callbacks
          if second_association_klass.logs_changes_for? first_association_name.pluralize
            # puts "SKIPPING #{self} -> has_many #{association_name} through: #{join_klass}."
            return
          end

          # Step 2: add callbacks
          join_klass.before_save -> (record) {

            break unless record.valid?

            if record.changes.include? "#{first_association_name}_id"
              # Step 4a: save event one
              @first_class_was = first_association_klass.find_by_id(record.send("#{second_association_name}_id_was"))
              @first_class_is = record.send(first_association_name)
            end

            if record.changes.include? "#{second_association_name}_id"
              # Step 4b: save event two
              @second_class_was = second_association_klass.find_by_id(record.send("#{second_association_name}_id_was"))
              @second_class_is = record.send(second_association_name)
            end

            @first_class_was.log_record_change(@second_class_was, nil, association_superordinate) if @second_class_was
            @first_class_is.log_record_change(nil, @second_class_is, association_superordinate) if @second_class_is
          }

          join_klass.before_destroy -> (record) {
            @first_class_was = first_association_klass.find_by_id(record.send("#{second_association_name}_id_was"))
            @first_class_is = record.send(first_association_name)
            @second_class_was = second_association_klass.find_by_id(record.send("#{second_association_name}_id_was"))
            @second_class_is = record.send(second_association_name)

            # Only need to call log_record_change once because
            # it will save event for other record as well

            if @first_class_was
              @first_class_was.log_record_change(@second_class_was, nil, association_superordinate)
            else
              @first_class_is.log_record_change(@second_class_was, nil, association_superordinate)
            end

          }

        else
          # puts "SKIPPING #{self} -> has_many #{association_name}"

          # raise "Only define logging for has_many through:, has_and_belongs_to_many, and belongs_to associations"
        end

        self._logged_associations << association_name

      end if associations_with_options
    end

    def self.logs_changes_for?(association_name)
      return false unless self.respond_to? :_logged_associations
      self._logged_associations.include? association_name.try(:to_sym)
    end
  end
end
