class Arrival < ActiveRecord::Base
  include LogsChanges
  has_many :shipments, through: :arrival_loads, dependent: :destroy
  has_many :arrival_loads
  has_many :users

  validates :number_of_trucks, numericality: {greater_than: 1}, allow_nil: true
end
