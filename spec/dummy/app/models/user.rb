class User < ActiveRecord::Base
  include Herstory
  belongs_to :arrival

  validates :name, length: {minimum: 3}, allow_nil: true
end
