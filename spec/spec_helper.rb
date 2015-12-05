require 'simplecov'
SimpleCov.start

def build_exception()
  begin
    1 / 0
  rescue ZeroDivisionError => exception
    return exception
  end
end

def build_rack_env()
  {
    "QUERY_STRING" => "a=1&b=2",
    "REMOTE_ADDR" => "::1",
    "REMOTE_HOST" => "localhost",
    "REQUEST_METHOD" => "GET",
    "REQUEST_PATH" => "/index.html",
    "HTTP_HOST" => "localhost:3000",
    "HTTP_VERSION" => "HTTP/1.1"
  }
end
