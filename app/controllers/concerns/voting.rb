module Voting
  include ActionView::Helpers::TextHelper

  def create_vote_for(option)
    poll = Poll.find(params[:poll_id])
    vote = poll.votes.new(user: current_user, option: option)
    if vote.save
      render json: vote_success_json(poll).merge(
        "pathA": poll_option_a_path(poll),
        "pathB": poll_option_b_path(poll),
        "methodA": option == 0 ? "delete" : "put",
        "methodB": option == 1 ? "delete" : "put",
        "option": option
      ), status: :accepted
    else
      render json: vote_error_json, status: :unprocessable_entity
    end
  end

  def update_vote_for(option)
    poll = Poll.find(params[:poll_id])
    vote = poll.votes.find_by(user_id: current_user.id)
    if vote.update(option: option)
      render json: vote_success_json(poll).merge(
      "pathA": poll_option_a_path(poll),
      "pathB": poll_option_b_path(poll),
      "methodA": option == 0 ? "delete" : "put",
      "methodB": option == 1 ? "delete" : "put",
      "option": option
    ), status: :accepted
    else
      render json: vote_error_json, status: :unprocessable_entity
    end
  end

  def destroy_vote_for(option)
    poll = Poll.find(params[:poll_id])
    vote = poll.votes.find_by(user_id: current_user.id)
    vote.destroy
    render json: vote_success_json(poll).merge(
      "delete": true,
      "optionA": 0.5,
      "optionB": 0.5,
      "pathA": poll_option_a_path(poll),
      "pathB": poll_option_b_path(poll),
      "methodA": "post",
      "methodB": "post"
    ), status: :accepted
  end


  def vote_error_json
    {
      "status": "error",
      "message": "Please try again"
    }
  end

  def vote_success_json(poll)
    {
      "status": "success",
      "delete": false,
      "poll": poll.id,
      "optionA": poll.fraction_of_votes(0),
      "optionB": poll.fraction_of_votes(1),
      "optionAText": poll.option_a,
      "optionBText": poll.option_b,
      "count": pluralize(poll.vote_count, "vote")
    }
  end
end
