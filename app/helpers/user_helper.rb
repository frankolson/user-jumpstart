module UserHelper
  def user_avatar(user, size=40)
    if user.avatar.attached?
      user.avatar.variant(combine_options: { resize: "#{size}x#{size}^",
        extent: "#{size}x#{size}", gravity: 'center' })
    else
      gravatar_image_url(user.email, size: size)
    end
  end
end
