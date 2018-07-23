class OptionBsController < ApplicationController
  def create
    @poll = Poll.find(params[:poll_id])
    @vote = @poll.votes.new(user: current_user, option: 1)
    if @vote.save
      render json: vote_success_json, status: :accepted
    else
      render json: vote_error_json, status: :unprocessable_entity
    end
  end

  def update
    @poll = Poll.find(params[:poll_id])
    @vote = @poll.votes.find_by(user_id: current_user.id)
    if @vote.update(option: 1)
      render json: vote_success_json, status: :accepted
    else
      render json: vote_error_json, status: :unprocessable_entity
    end
  end
  
  
  private 
  def vote_error_json
    @hash =  {
        "status": "error",
        "message": "Please try again"
        }
  end
  
  def vote_success_json
    @hash = {
        "status": "success",
        "poll": @poll.id,
        "optionA": @poll.fraction_of_votes(0),
        "optionB": @poll.fraction_of_votes(1)
      }
  end
end
