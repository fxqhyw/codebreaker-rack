require 'rack/test'
require_relative '../lib/racker'

RSpec.describe Racker do
  include Rack::Test::Methods

  def app
    Rack::Builder.parse_file('config.ru').first
  end

  let(:response_200) { expect(last_response.status).to eq(200) }
  let(:response_302) { expect(last_response.status).to eq(302) }

  context 'not found' do
    before { get '/nonexistent' }

    it 'returns code 404' do
      expect(last_response.status).to eq(404)
    end

    it 'returns body text: Not Found' do
      expect(last_response.body).to eq('Not Found')
    end
  end

  context '/' do
    before { get '/' }

    it 'returns code 200' do
      response_200
    end

    it 'stores instance of Game to the session' do
      expect(last_request.session[:game]).to be_an_instance_of(Codebreaker::Game)
    end
  end

  context '/guess' do
    it 'returns code 302' do
      post '/guess?guess=1234'
      response_302
    end
  end

  context '/score' do
    before { get '/score' }
    it 'returns code 200' do
      response_200
    end

    it 'returns body scores' do
      expect(last_response.body).to include('SCORE')
    end
  end

  context '/hint' do
    before { post '/hint' }

    it 'returns code 302' do
      response_302
    end

    it 'stores hint to the session' do
      expect(last_request.session[:hint]).to be_a(Integer)
    end
  end

  context '/restart' do
    before { get '/restart' }

    it 'returns code 302' do
      response_302
    end

    it 'clears the session' do
      expect(last_request.session[:game]).to be_nil
      expect(last_request.session[:game_status]).to be_nil
      expect(last_request.session[:hint]).to be_nil
    end
  end
end
