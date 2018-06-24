require 'erb'
require 'codebreaker'

class Racker
  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
  end

  def response
    case @request.path
    when '/' then index
    else
      Rack::Response.new('Not Found', 404)
    end
  end

  private

  def index
    @game ||= Codebreaker::Game.new
    Rack::Response.new(render('index.html.erb'))
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end
end
