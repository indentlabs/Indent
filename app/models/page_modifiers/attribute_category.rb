#<AttributeCategory
#  id: nil,
#  user_id: nil,
#  entity_type: nil,
#  name: nil,
#  label: nil,
#  icon: nil,
#  description: nil,
#  created_at: nil,
#  updated_at: nil>
class AttributeCategory < ActiveRecord::Base
  validates :name, presence: true

  belongs_to :user
  has_many   :attribute_fields

  include HasAttributes
  include Serendipitous::Concern

  include Authority::Abilities
  self.authorizer_name = 'AttributeAuthorizer'

  before_validation :ensure_name

  after_create do
    # Create a mirrored PageCategory
    PageCategory.create(
      label: self.label,
      universe: nil,
      content_type: self.entity_type.titleize,
      user: self.user
    )
  end

  after_destroy do
    # Destroy the mirrored PageCategory
    category = mirrored_page_category
    category.destroy if category
  end

  def mirrored_page_category
    PageCategory.find_by(
      label: self.label,
      universe: nil,
      user: self.user,
      content_type: self.entity_type.titleize
    )
  end

  def self.color
    'amber'
  end

  def self.icon
    'folder_open'
  end

  def self.content_name
    'attribute_category'
  end

  def icon
    self['icon'] || self.class.icon
  end

  private

  def ensure_name
    self.name ||= "#{label}-#{Time.now.to_i}".underscore.gsub(' ', '_')
  end
end
