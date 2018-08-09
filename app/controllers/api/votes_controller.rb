class Api::VotesController < Api::ApiController
  include ActionView::Helpers::TextHelper

  before_action :verify_poll_id
  before_action :verify_vote_type
  before_action :verify_ip_or_user
  before_action :verify_option, only: [:create, :update]

  def create
    vote = if @type == "visitor"
      @poll.visitor_votes.new(ip_address: @ip_address, option: @option)
    else
      @poll.votes.new(user: @user, option: @option)
    end

    if vote.save
      render json: vote_success_json(@poll).merge(
        option: @option
        ), status: :ok
    else
      respond_with_error("Vote unable to be created")
    end
  end

  def update
    vote = if @type == "visitor"
      @poll.visitor_votes.find_by(ip_address: @ip_address)    
    else
      @poll.votes.find_by(user_id: @user.id)
    end
    
    if vote.update(option: @option)
      render json: vote_success_json(@poll).merge(
        option: @option
        ), status: :ok
    else
      respond_with_error("Vote unable to be updated")
    end
  end

  def destroy
    vote = if @type == "visitor"
      @poll.visitor_votes.find_by(ip_address: @ip_address)    
    else
      @poll.votes.find_by(user_id: @user.id)
    end
    
    if vote.destroy
      render json: vote_success_json(@poll).merge(
        "delete": true,
        "optionA": 0.5,
        "optionB": 0.5
      )
    else
      respond_with_error("Vote unable to be deleted")
    end
  end

  private
  def vote_type
    @type ||= params[:type]
  end
  
  def vote_option
    @option ||= params[:option]
  end
  
  def verify_ip_address
    @ip_address = params[:ip_address]
    if !@ip_address.present?
      respond_with_error("Invalid IP Address")
    end
  end

  def verify_vote_type
    if !vote_type.present? || (vote_type != "visitor" && vote_type != "user")
      respond_with_error("Invalid voting type")
    end
  end

  def verify_ip_or_user
    if vote_type == "visitor"
      verify_ip_address
    else
      verify_user_id
    end
  end

  def verify_option
    if !vote_option.present?
      respond_with_error("No option given")
    elsif vote_option != "1" && vote_option != "0"
      respond_with_error("Invalid Option")
    else
      @option = @option.to_i
    end
  end

  def respond_no_vote_given
    render json: {
      status: "success",
      has_vote: false,
      poll: @poll.id,
    }, status: :ok
  end

  def respond_with_vote_given(option)
    render json: {
      status: "success",
      has_vote: true,
      poll: @poll.id,
      option: option
    }, status: :ok
  end

  def vote_success_json(poll)
    {
      "status": "success",
      "delete": false,
      "poll": poll.id,
      "optionA": poll.fraction_of_votes(0),
      "optionB": poll.fraction_of_votes(1),
      "count": pluralize(poll.vote_count, "vote")
    }
  end
end