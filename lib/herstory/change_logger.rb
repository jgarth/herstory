class ChangeLogger
  def self.log_creation(record, user=nil)
    record.log(type: 'created', user: user)
  end

  def self.log_association_change(change, record, superordinate, other_record, skip_logging_on_other=false, user=nil)
    unless %i( record other_record both none ).include? superordinate
      raise ArgumentError.new("Unknown value for ordinate '#{superordinate}'")
    end

    log_key_for_model = change == :addition ? :newly_associated_object : :previously_associated_object

    record.log({
      :type => event_type(
        change: change,
        model: other_record,
        superordinate: (superordinate == :record || superordinate == :both)
      ),
      log_key_for_model => other_record,
      :user => user
    })

    unless skip_logging_on_other
      other_record.log({
        :type => event_type(
          change: change,
          model: record,
          superordinate: (superordinate == :other_record || superordinate == :both)
        ),
        log_key_for_model => record,
        :user => user
      })
    end
  end

  def self.event_type(change:, model:, superordinate:)
    model_name = model.model_name.i18n_key

    verb, preposition =
      if change == :addition then ['attached', 'to']
                             else ['detached', 'from'] end

    if superordinate
      "#{model_name}_#{verb}"
    else
      "#{verb}_#{preposition}_#{model_name}"
    end
  end

  #
  # Creates an event for every attribute that was updated
  #
  # Takes two arguments:
  # - record: record that was updated
  # - user: the user responsible for making the changes
  def self.log_attribute_changes(record, user=nil)
    # Return here to not save changes when the model won't save anyway
    return unless record.valid?

    # Get a list of changed fields
    record.changes.each_pair do |key, value_array|
      value_was, value = value_array

      # Skip event logging for excluded keys
      next if record.class._excluded_columns.map(&:to_sym).include? key.to_sym

      # Skip event logging for created_at, updated_at
      next if %w( created_at updated_at ).include? key

      # Delegate association logging
      next if key.ends_with? "_id"

      # Skip event logging when value was set from nil to ""
      next if value_was.blank? && value.blank? && !(value === false)


      # Replace values by translated value if matching class const was found
      #
      # e.g. attribute name is damage_severity
      #      look for class constant: DAMAGE_SEVERITIES
      #      if found, look for translation under: <locale>.damage_severities
      # if not translateable => just leave the original value as it is
      if record.class.const_defined?(const_name = key.to_s.pluralize.upcase)
        value     = I18n.t(value, scope: key.to_s.pluralize, default: value.to_s) rescue value
        value_was = I18n.t(value_was, scope: key.to_s.pluralize, default: value_was.to_s) rescue value_was
      end

      record.log(
        type: "#{key}_changed",
        user: user,
        previous_value: formatted_value_or_unknown(value_was),
        new_value: formatted_value_or_unknown(value)
      )
    end
  end

  def self.formatted_value_or_unknown(value)
    # Return 'unknown' if value is nil or empty
    return nil if value.blank? && !(value === false)

    # Try to format values
    if value.is_a? ActiveSupport::TimeWithZone
      return I18n.localize value
      # Fallback: return value unchanged
    elsif value.is_a? Array
      return value.join(', ')
    else
      return value
    end
  end
end
