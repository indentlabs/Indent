##
# = u-ni-verse
# == /'yoone,vers/
#
# 1. a particular sphere of activity, interest, or experience
#
#    contains all canonically-related content created by Users
class Universe < ActiveRecord::Base
  acts_as_paranoid

  include HasAttributes
  include HasPrivacy
  include HasImageUploads
  include HasChangelog

  include Serendipitous::Concern

  include Authority::Abilities
  self.authorizer_name = 'UniverseCoreContentAuthorizer'

  validates :name, presence: true
  validates :user_id, presence: true

  belongs_to :user
  # The following doesn't work because we reference Universe when setting up this config
  # Rails.application.config.content_types[:all_non_universe].each do |content_type|
  #   has_many content_types.name.downcase.pluralize.to_sym
  # end
  has_many :characters
  has_many :countries
  has_many :creatures
  has_many :deities
  has_many :floras
  has_many :governments
  has_many :groups
  has_many :items
  has_many :landmarks
  has_many :languages
  has_many :locations
  has_many :magics
  has_many :planets
  has_many :races
  has_many :religions
  has_many :scenes
  has_many :technologies
  has_many :towns

  has_many :contributors, dependent: :destroy

  # V2 woo woo!
  has_many :page_categories, dependent: :destroy
  has_many :page_fields, through: :page_categories

  scope :is_public, -> { where(privacy: 'public') }

  after_destroy do
    Rails.application.config.content_types[:all_non_universe].each do |content_type|
      content_type.where(universe_id: self.id).update_all(universe_id: nil)
    end
  end

  after_create do
    Universe.create_default_page_categories_and_fields!(self)
    content_classes = Rails.application.config.content_types[:all_non_universe]
    content_classes.each do |content_class|
      content_class.create_default_page_categories_and_fields!(self)
    end
  end

  def content_count
    content.count
  end

  def self.color
    'purple'
  end

  def self.icon
    'language'
  end

  def self.content_name
    'universe'
  end
end
