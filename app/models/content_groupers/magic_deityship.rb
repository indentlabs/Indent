class MagicDeityship < ActiveRecord::Base
  include HasContentLinking

  belongs_to :user

  belongs_to :magic
  belongs_to :deity, class_name: 'Character'
end