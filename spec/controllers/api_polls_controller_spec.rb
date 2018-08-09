require "rails_helper"

RSpec.describe Api::PollsController, type: :controller do
  let!(:token) {Rails.application.credentials.dig(:app_key)}

  context "with a poll and a user" do
    let!(:user) {create(:user)}
    let!(:poll_1) {create(:poll, user: user, title: 'Example Poll 1', option_a: 'Choice 1', option_b: 'Choice 2')}

    context "with invalid parameters" do
      it 'responds with invalid poll id' do
        get :show, params: {
          token: token,
          id: 0
        }

        expect(response.body).to eq({
          "status": "error",
          "message": "Invalid Poll ID"
        }.to_json)
      end

      it 'responds with invalid user id' do
        post :create, params: {
          token: token,
          user_id: 0,
          poll: attributes_for(:poll,
            title: "API Created Poll",
            option_a: "Left", 
            option_b: "Right"
            ).except(:expiry_time, :expired).merge(
              expire: {
                days: 1,
                hours: 0,
                mins: 0
            })
        }

        expect(response.body).to eq({
          "status": "error",
          "message": "Invalid User ID"
        }.to_json)
      end
    end
    
    context "with valid parameters" do
      let!(:poll_2) {create(:poll, user: user, title: 'Another Poll 1', option_a: 'Decision 1', option_b: 'Decision 2')}
      
      it 'gets all polls' do
        get :index, params: {
          token: token,
          user_id: user.id
        }
        expect(response.body).to eq({
          "status": "success",
          poll: [poll_2, poll_1]
        }.to_json)
      end
      
      it 'shows a single poll' do
        get :show, params: {
          token: token,
          user_id: user.id,
          id: poll_2.id
        }
        
        expect(response.body).to eq({
          "status": "success",
          poll: poll_2
        }.to_json)
      end
      
      it 'creates a poll' do
        post :create, params: {
          token: token,
          user_id: user.id,
          poll: attributes_for(:poll,
            title: "API Created Poll",
            option_a: "Left", 
            option_b: "Right"
            ).except(:expiry_time, :expired).merge(
              expire: {
                days: 1,
                hours: 0,
                mins: 0
            })
        }

        poll = Poll.last
        expect(response.body).to eq({
          "status": "success",
          "poll": poll
        }.to_json)
      end
    end
  end
end