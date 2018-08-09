require "rails_helper"

RSpec.describe Api::VotesController, type: :controller do
  let!(:token) {Rails.application.credentials.dig(:app_key)}
  
  #I am creating a mock IP address because in the app, I'll have to pass in IP address of the user's phone. The IP adress will be found immediately when the user starts up the app.
  let!(:ip) {"127.0.0.1"}
  
  context "with existing polls and users" do
    let!(:user) {create(:user)}
    let!(:poll) {create(:poll)}
    
    it 'responds with error with invalid vote type' do
      post :create, params: {
        token: token,
        poll_id: poll.id,
        user_id: user.id,
        option: "0",
        type: "invalid"
        }
      
      expect(response.body).to eq({
        status: "error",
        message: "Invalid voting type"
      }.to_json)
      expect(response.status).to eq(422)
    end
    
    it 'responds with invalid option type' do
      post :create, params: {
        token: token,
        poll_id: poll.id,
        user_id: user.id,
        type: "user",
        option: "2"
      }
      
      expect(response.body).to eq({
        status: "error",
        message: "Invalid Option"
      }.to_json)
      expect(response.status).to eq(422)
    end
  
    describe "voting as a user" do
      it 'creates a vote for the user' do
        post :create, params: {
          token: token,
          poll_id: poll.id,
          user_id: user.id,
          type: "user",
          option: "0"
        }
        
        expect(Vote.count).to eq(1)
        expect(Vote.first.user).to eq(user)
        expect(Vote.first.option).to eq(0)
      end
      
      it 'updates a vote for the user' do
        create(:vote, user: user, poll: poll, option: 0)
        expect(Vote.count).to eq(1)
        
        put :update, params: {
          token: token,
          poll_id: poll.id,
          user_id: user.id,
          type: "user",
          option: "1"
        }
        
        expect(Vote.count).to eq(1)
        expect(Vote.first.user).to eq(user)
        expect(Vote.first.option).to eq(1)
      end
      
      it 'deleted a vote for the user' do
        create(:vote, user: user, poll: poll, option: 0)
        expect(Vote.count).to eq(1)
        
        delete :destroy, params: {
          token: token,
          poll_id: poll.id,
          user_id: user.id,
          type: "user",
          option: "0"
        }
        
        expect(Vote.count).to eq(0)
      end
    end
    
    describe "voting as a visitor" do
      it 'creates a vote for the visitor' do
        post :create, params: {
          token: token,
          poll_id: poll.id,
          ip_address: ip,
          type: "visitor",
          option: "0"
        }
        
        expect(VisitorVote.count).to eq(1)
        expect(VisitorVote.first.ip_address).to eq(ip)
        expect(VisitorVote.first.option).to eq(0)
      end
      
      it 'updates a vote for the visitor' do
        create(:visitor_vote, ip_address: ip, poll: poll, option: 0)
        expect(VisitorVote.count).to eq(1)
        
        put :update, params: {
          token: token,
          poll_id: poll.id,
          ip_address: ip,
          type: "visitor",
          option: "1"
        }
        
        expect(VisitorVote.count).to eq(1)
        expect(VisitorVote.first.ip_address).to eq(ip)
        expect(VisitorVote.first.option).to eq(1)
      end
      
      it 'deleted a vote for the visitor' do
        create(:visitor_vote, ip_address: ip, poll: poll, option: 0)
        expect(VisitorVote.count).to eq(1)
        
        delete :destroy, params: {
          token: token,
          poll_id: poll.id,
          ip_address: ip,
          type: "visitor",
          option: "0"
        }
        
        expect(VisitorVote.count).to eq(0)
      end
    end
  end
end