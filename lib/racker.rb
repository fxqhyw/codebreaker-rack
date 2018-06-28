require 'erb'
require 'yaml'
require 'codebreaker'

class Racker
  DATABASE = './lib/data/score.yml'.freeze

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
    when '/restart' then restart
    when '/save' then save_result
    when '/score' then score
    else
      Rack::Response.new('Not Found', 404)
    end
  end

  private

  def index
    Rack::Response.new(render('index.html.erb'))
  end

  def score
    restart
    Rack::Response.new(render('score.html.erb'))
  end

  def make_guess
    result = @game.make_guess(@request.params['guess'])
    save_game
    @request.session[:game_status] = 'won' if result == '++++'
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

  def restart
    @request.session[:game] = nil
    @request.session[:game_status] = nil
    @request.session[:hint] = nil

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

  def save_result
    result = { name: @request.params['name'], attempts: @game.used_attempts.to_s, hints: @game.used_hints.to_s,
               date: Time.now.strftime('%d-%m-%Y %R') }
    File.open(DATABASE, 'a') { |f| f.write(result.to_yaml) }

    Rack::Response.new do |response|
      response.redirect('/score')
    end
  end

  def load_score
    file = File.open(DATABASE)
    YAML.load_stream(file)
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
