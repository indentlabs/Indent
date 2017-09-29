class GroupEquipmentship < ActiveRecord::Base
  include HasContentLinking

  belongs_to :user

  belongs_to :group
  belongs_to :equipment, class_name: 'Item'
end