class Event < ActiveRecord::Base
  self.inheritance_column = 'not_type'

  #
  # Associations
  #
  belongs_to :parent, polymorphic: true
  belongs_to :user
  belongs_to :previously_associated_object, polymorphic: true
  belongs_to :newly_associated_object, polymorphic: true

  #
  # Validations
  #
  validates :parent, presence: true

  #
  # Scopes
  #
  default_scope { order('events.created_at desc') }
end
