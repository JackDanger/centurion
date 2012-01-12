See -> console.log.apply this, arguments

require.paths.unshift('./vendor')
require('web')


for i in process.argv
  if '--port' == process.argv[i]
    Web.port = process.argv[parseInt(i)+1]
    require('sys').puts "Starting Centurion web app on port "+Web.port
    Web.listen Web.port
