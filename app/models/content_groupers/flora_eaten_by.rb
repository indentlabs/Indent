class FloraEatenBy < ActiveRecord::Base
  include HasContentLinking

  belongs_to :user

  belongs_to :flora
  belongs_to :creature
end
