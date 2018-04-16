module Herstory
  extend ActiveSupport::Concern

  included do
    include HasEvents

    cattr_accessor(:_excluded_columns) { [] }

    def self.logs_changes(options = {})
      # Don't do anything if this is not the first
      # call to logs_changes
      return if self.logs_changes_for? :self

      # This part does change logging on the model
      self.class_eval do
        cattr_accessor :_logged_associations do
          [:self]
        end

        after_save RecordCallbacks.new
      end

      # extract excluded columns option
      excluded_columns = options.delete(:exclude_columns)
      self._excluded_columns = excluded_columns || []

      associations_with_options = Herstory.clean_options(options)
      associations_with_options.each do |association_name, association_options|

        association_superordinate = association_options[:superordinate] || :both

        Herstory.setup_association_logging(self, association_name, association_superordinate)
        self._logged_associations << association_name

      end if associations_with_options
    end

    def self.logs_changes_for?(association_name)
      return false unless self.respond_to? :_logged_associations
      self._logged_associations.include? association_name.try(:to_sym)
    end
  end

  #
  # Skip logging inside a given block
  #
  def self.without_logging(&block)
    begin
      Thread.current[:skip_logging] = true
      yield
    ensure
      Thread.current[:skip_logging] = false
    end
  end

  #
  # Setup logging for a single association
  #
  def self.setup_association_logging (record, association_name, association_superordinate)
    reflection = record.reflect_on_association(association_name)

    raise ArgumentError.new("Unknown association '#{association_name}'") unless reflection

    if reflection.belongs_to?

      # Rails.logger.debug("[HERSTORY] Monitoring association #{reflection.name} on #{record}")

      record.after_save BelongsToCallbacks.new(
          reflection: reflection,
          superordinate: association_superordinate
      ), if: "saved_change_to_#{association_name}_id?".to_sym

    elsif reflection.collection? && reflection.through_reflection
      # Go for join model's belongs_to assocs instead
      join_klass = reflection.through_reflection.klass

      # Make sure the join-model association is dependent destroy
      # Otherwise callbacks will not be triggered
      unless reflection.options[:dependent] == :destroy
        raise ArgumentError.new("Association #{reflection.name} on #{record} must be declared dependent: :destroy")
      end

      # Check if the other side already registered callbacks
      if reflection.klass && reflection.klass.logs_changes_for?(record.model_name.element.pluralize)
        # Rails.logger.debug("[HERSTORY] NOT monitoring association #{reflection.name} on #{record} via #{join_klass} because it is already monitored by other side")
        return
      end

      # Rails.logger.debug("[HERSTORY] Monitoring association #{reflection.name} on #{record} via #{join_klass}")

      callback_handler = HasManyThroughCallbacks.new(
          record: record,
          reflection: reflection,
          superordinate: association_superordinate
        )

      # join_klass.before_save callback_handler
      join_klass.before_destroy callback_handler
      join_klass.after_save callback_handler
      # join_klass.after_destroy callback_handler

    elsif reflection.macro == :has_and_belongs_to_many
      callback_handler = HasAndBelongsToManyCallbacks.new(
        record: record,
        reflection: reflection,
        superordinate: association_superordinate
      )

      record.send("after_add_for_#{reflection.name}") << callback_handler.after_add
      record.send("after_remove_for_#{reflection.name}") << callback_handler.after_remove

    else
      # Rails.logger.debug "[HERSTORY] Tried to define logging for #{reflection.name} (#{reflection.macro}) on #{record}, which is not supported."

    end
  end

  #
  # Clean options given to logs_changes
  #
  def self.clean_options(options = {})
    raise ArgumentError.new("Unknown option format: #{options}.") unless options.is_a? Hash

    includes = options.delete(:includes)
    raise ArgumentError.new("Unknown options '#{options.keys.join(',')}' for log_changes.") if options.keys.count > 0

    includes = includes.flat_map do |included|
        [*included].map{|k,v| [k, v || {}]}
    end.to_h if includes.is_a? Array

    includes || {}
  end
end
