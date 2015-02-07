module Herstory
  extend ActiveSupport::Concern

  included do
    include HasEvents

    def self.logs_changes(options = {})
      # This part does change logging on the model
      self.class_eval do
        cattr_accessor :_logged_associations do
          []
        end

        after_save RecordCallbacks.new
      end

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

      record.before_save BelongsToCallbacks.new(
          reflection: reflection,
          superordinate: association_superordinate
        ), if: "#{association_name}_id_changed?"

    elsif reflection.collection? && reflection.through_reflection
      # Check if the other side already registered callbacks
      return if reflection.klass && reflection.klass.logs_changes_for?(record.model_name.plural)

      # Go for join model's belongs_to assocs instead
      join_klass = reflection.through_reflection.klass

      callback_handler = HasManyThroughCallbacks.new(
          record: record,
          reflection: reflection,
          superordinate: association_superordinate
        )

      join_klass.before_save callback_handler
      join_klass.before_destroy callback_handler

    else
      # raise "Only define logging for has_many through:, has_and_belongs_to_many, and belongs_to associations"
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
