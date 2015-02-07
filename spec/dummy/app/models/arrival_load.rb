# Join model
class ArrivalLoad < ActiveRecord::Base
  include Herstory

  belongs_to :arrival
  belongs_to :shipment

  validates :pieces_checkedin, numericality: {greater_than: 1}, allow_nil: true
end
