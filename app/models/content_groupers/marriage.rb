class Marriage < ActiveRecord::Base
  include HasContentLinking
  LINK_TYPE = :two_way

  belongs_to :user

  belongs_to :character
  belongs_to :spouse, class_name: 'Character'

  after_create do
    self.reciprocate relation: :marriages, parent_object_ref: :character, added_object_ref: :spouse
  end

  after_destroy do
    # This is a two-way relation, so we should also delete the reverse association
    this_object  = Character.find_by(id: self.character_id)
    other_object = Character.find_by(id: self.spouse_id)

    other_object.spouses.delete this_object
  end

  #todo "active" marriage?
end
