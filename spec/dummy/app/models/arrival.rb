class Arrival < ActiveRecord::Base
  include Herstory
  has_many :arrival_loads
  has_many :shipments, through: :arrival_loads, dependent: :destroy
  has_many :users
  has_many :notes, as: :parent

  validates :number_of_trucks, numericality: {greater_than: 1}, allow_nil: true
end
