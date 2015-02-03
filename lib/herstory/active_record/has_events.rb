module HasEvents
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :parent
  end

  def log(attr)
    event = events.build(attr)
    event.save! unless new_record?
  end
end
