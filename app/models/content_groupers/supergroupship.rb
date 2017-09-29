class Supergroupship < ActiveRecord::Base
  include HasContentLinking

  belongs_to :user

  belongs_to :group
  belongs_to :supergroup, class_name: 'Group'

  after_create do
    this_object  = Group.find_by(id: self.group_id)
    other_object = Group.find_by(id: self.supergroup_id)

    other_object.subgroupships.create(group: other_object, subgroup: this_object) unless other_object.subgroups.include? this_object
  end

  after_destroy do
    # This is a two-way relation, so we should also delete the reverse association
    this_object  = Group.find_by(id: self.group_id)
    other_object = Group.find_by(id: self.supergroup_id)

    other_object.subgroups.delete this_object
  end
end