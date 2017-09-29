class Subgroupship < ActiveRecord::Base
  include HasContentLinking

  belongs_to :user

  belongs_to :group
  belongs_to :subgroup, class_name: 'Group'

  after_create do
    this_object  = Group.find_by(id: self.group_id)
    other_object = Group.find_by(id: self.subgroup_id)

    other_object.supergroupships.create(group: other_object, supergroup: this_object) unless other_object.supergroups.include? this_object
  end

  after_destroy do
    # This is a two-way relation, so we should also delete the reverse association
    this_object  = Group.find_by(id: self.group_id)
    other_object = Group.find_by(id: self.subgroup_id)

    other_object.supergroups.delete this_object
  end
end