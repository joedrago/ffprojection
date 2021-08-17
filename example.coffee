Mapping = require './Mapping'
{execSync} = require 'child_process'

run = (cmd) ->
  execSync(cmd, { stdio: 'inherit' })
  return

main = ->
  console.log "Generating UV mapping..."
  m = new Mapping(1280, 720, 640, 360)
  m.project [
    74, 218,
    306, 220,
    310, 374,
    88, 420,
  ]

  console.log "Writing PGMs..."
  m.write("biden4x.pgm", "biden4y.pgm", "biden4a.pgm")

main()

