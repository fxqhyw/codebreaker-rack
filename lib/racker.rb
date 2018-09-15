# frozen_string_literal: true
require 'erb'
require 'yaml'
require 'codebreaker'

class Racker
  SCORE_DATABASE = './lib/data/score.yml'
  GAME_DATABASE = './lib/data/game.yml'
  WINNING_RESULT = '++++'
  ROUTES = {
    '/' => :index,
    '/guess' => :make_guess,
    '/hint' => :hint,
    '/restart' => :restart,
    '/save' => :save_result,
    '/score' => :score
  }.freeze

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    load_game
  end

  def response
    return send(ROUTES[@request.path]) if @request.path
    Rack::Response.new('Not Found', 404)
  end

  private

  def index
    Rack::Response.new(render('index.html.erb'))
  end

  def score
    Rack::Response.new(render('score.html.erb'))
  end

  def load_game
    if @request.session[:game_init?]
      file = File.open(GAME_DATABASE)
      @game = YAML.load_file(file)
    else
      @request.session[:game_init?] = true
      @game = Codebreaker::Game.new
      save_game
    end
  end

  def make_guess
    result = @game.make_guess(@request.params['guess'])
    save_game
    @request.session[:game_won?] = true if result == WINNING_RESULT

    redirect_to('/')
  end

  def hint
    @request.session[:hint] = @game.hint
    save_game

    redirect_to('/')
  end

  def restart
    @request.session[:game_init?] = nil
    @request.session[:game_won?] = nil
    @request.session[:hint] = nil

    redirect_to('/')
  end

  def save_game
    File.open(GAME_DATABASE, 'w') { |f| f.write(@game.to_yaml) }
  end

  def save_result
    result = { name: @request.params['name'], attempts: @game.used_attempts.to_s, hints: @game.used_hints.to_s,
               date: Time.now.strftime('%d-%m-%Y %R') }
    File.open(SCORE_DATABASE, 'a') { |f| f.write(result.to_yaml) }

    redirect_to('/score')
  end

  def load_score
    file = File.open(SCORE_DATABASE)
    YAML.load_stream(file)
  end

  def redirect_to(path)
    Rack::Response.new do |response|
      response.redirect(path)
    end
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
