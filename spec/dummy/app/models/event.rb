class Event < ActiveRecord::Base
  self.inheritance_column = 'not_type'

  #
  # Associations
  #
  belongs_to :parent, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :previously_associated_object, polymorphic: true, optional: true
  belongs_to :newly_associated_object, polymorphic: true, optional: true

  #
  # Scopes
  #
  default_scope { order('events.created_at DESC') }
end
