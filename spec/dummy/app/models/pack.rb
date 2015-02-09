class Pack < ActiveRecord::Base
  include Herstory

  has_and_belongs_to_many :shipments
end
