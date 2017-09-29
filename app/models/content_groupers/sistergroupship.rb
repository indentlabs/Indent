class Sistergroupship < ActiveRecord::Base
  include HasContentLinking

  belongs_to :user

  belongs_to :group
  belongs_to :sistergroup, class_name: 'Group'

  after_create do
    self.reciprocate relation: :sistergroupships, parent_object_ref: :group, added_object_ref: :sistergroup
  end

  after_destroy do
    # This is a two-way relation, so we should also delete the reverse association
    this_object  = Group.find_by(id: self.group_id)
    other_object = Group.find_by(id: self.sistergroup_id)

    other_object.sistergroups.delete this_object
  end
end