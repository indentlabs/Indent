# Defines a relation between a location and any capital cities within it,
# and a reverse relation for all locations in which they are the capital of.
class CapitalCitiesRelationship < ActiveRecord::Base
  include HasContentLinking

  belongs_to :user

  belongs_to :location
  belongs_to :capital_city, class_name: 'Location'
end
