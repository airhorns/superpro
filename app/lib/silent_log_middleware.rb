# Rack middleware to silence the logger for stuff we don't need.
# Uses semantic_logger's Logger#silence to do stuff, so it's simple.
# Based on https://github.com/stve/silencer
class SilentLogMiddleware
  METHODS = %i[options get head post put delete trace connect patch]

  def initialize(app, options = {})
    @app = app
    @silence = wrap(options.delete(:silence))
    @routes = define_routes(@silence, options)
  end

  def call(env)
    if silent_request?(env)
      Rails.logger.silence(:error) do
        @app.call(env)
      end
    else
      @app.call(env)
    end
  end

  def define_routes(silence_paths, opts)
    METHODS.each_with_object({}) do |method, routes|
      routes[method.to_s.upcase] = wrap(opts.delete(method)) + silence_paths
      routes
    end
  end

  def wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
  end

  def silent_request?(env)
    (@routes[env["REQUEST_METHOD"]] || @silence).any? do |rule|
      case rule
      when String, Integer
        rule.to_s == env["PATH_INFO"]
      when Regexp
        rule =~ env["PATH_INFO"]
      else
        false
      end
    end
  end
end
