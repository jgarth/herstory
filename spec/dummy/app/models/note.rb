class Note < ActiveRecord::Base
  include LogsChanges

  belongs_to :parent, polymorphic: true
  belongs_to :user

  validates :parent, :user, presence: true

  default_scope { order('notes.created_at DESC') }
end
