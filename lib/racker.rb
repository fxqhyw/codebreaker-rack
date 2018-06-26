require 'erb'
require 'yaml'
require 'codebreaker'

class Racker
  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @game = load_game
  end

  def response
    case @request.path
    when '/' then index
    when '/guess' then make_guess
    when '/hint' then hint
    else
      Rack::Response.new('Not Found', 404)
    end
  end

  private

  def index
    Rack::Response.new(render('index.html.erb'))
  end

  def make_guess
    @game.make_guess(@request.params['guess'])
    save_game
    Rack::Response.new do |response|
      response.redirect('/')
    end
  end

  def hint
    @request.session[:hint] = @game.hint
    save_game
    Rack::Response.new do |response|
      response.redirect('/')
    end
  end

  def load_game
    @request.session[:game] ||= Codebreaker::Game.new
  end

  def save_game
    @request.session[:game] = @game
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
