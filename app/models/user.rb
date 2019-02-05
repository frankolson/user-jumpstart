class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
    :validatable

  has_person_name
  has_one_attached :avatar

  validate :correct_image_format?

  private
    def correct_image_format?
      if avatar.attached? && !avatar.image?
        avatar.purge_later
        errors.add(:avatar, 'needs to be an image')
      end
    end
end
