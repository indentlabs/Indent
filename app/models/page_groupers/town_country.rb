class TownCountry < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :town
  belongs_to :country, optional: true
end
