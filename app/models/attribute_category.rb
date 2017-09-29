class AttributeCategory < ActiveRecord::Base
  validates :name, presence: true

  belongs_to :user
  has_many   :attribute_fields

  include HasAttributes
  include Serendipitous::Concern

  include Authority::Abilities
  self.authorizer_name = 'CoreContentAuthorizer'

  before_validation :ensure_name

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
