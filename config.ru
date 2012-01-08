require 'rack/static'

use Rack::Static, :root => "public",   # static files root dir
                     :urls => %w[/],     # match all requests 
                     :try => ['.html', 'index.html', '/index.html'] # try these postfixes sequentially
# otherwise 404 NotFound
run lambda { [404, {'Content-Type' => 'text/html'}, ['whoops! Not Found']]}
