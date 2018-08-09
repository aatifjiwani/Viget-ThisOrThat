class Api::PollsController < Api::ApiController
  before_action :verify_user_id, only: :create
  before_action :verify_poll_id, only: :show
  before_action :verify_ip_or_user_id, only: [:index, :show]

  def index
    if params[:filter] == "popular" 
      render json: {
        status: "success",
        poll: Poll.popular.as_json(ip: @ip_address, user: @user)
        }, status: :accepted
    else
      render json: {
        status: "success",
        poll: Poll.recent.as_json(ip: @ip_address, user: @user)
        }, status: :accepted
    end
  end

  def create
    poll = @user.polls.new(poll_params.merge(expired: false))
    if poll.save 
      render json: {
        status: "success",
        poll: poll
        }, status: :accepted
    else
      render json: {
        status: "error",
        message: poll.errors.full_messages
        }, status: :unprocessable_entity
    end
  end

  def show
    render json: {
      status: "success",
      poll: @poll.as_json(ip: @ip_address, user: @user)
      }, status: :accepted
  end

  private
  def poll_params
    params.require(:poll).permit(
      :title, 
      :option_a_url, 
      :option_b_url, 
      :option_a, 
      :option_b, 
      expire: [
        :days, 
        :hours, 
        :mins
        ]
      )
  end
  
  def verify_ip_or_user_id
    if params[:ip_address].present?
      @ip_address = params[:ip_address]
    elsif params[:user_id].present?
      @user = params[:user_id]
    else
      respond_with_error("Invalid parameters")
    end
  end
  
  def verify_poll_id
    @poll = Poll.find_by(id: params[:id]) if params[:id].present?
    if @poll.nil?
      respond_with_error("Invalid Poll ID")
    end
  end
end