class RegistrationController < Devise::RegistrationsController
  include ActionView::Helpers::TagHelper

  def create
    @user = User.new(sign_up_params)
    if @user.save
      set_flash_message! :notice, :signed_up
      sign_up("user", @user)
      cookies.signed.permanent[:user_id] = @user.id
      render json: {
        "status": "success",
        }
    else
      clean_up_passwords @user
      set_minimum_password_length
      render json: {
        "status": "error",
        "message": error_messages.to_s
        }, status: :unprocessable_entity
    end
  end

  private
  def sign_up_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :current_password)
  end

  def error_messages 
    if @user
      return "" if @user.errors.empty?

      messages = @user.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    end
  end
end
