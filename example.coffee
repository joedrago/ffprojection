Mapping = require './Mapping'
{execSync} = require 'child_process'

run = (cmd) ->
  execSync(cmd, { stdio: 'inherit' })
  return

main = ->
  console.log "Generating UV mapping..."
  m = new Mapping(1280, 720)
  m.project [
    74, 218,
    306, 220,
    310, 374,
    88, 420,
  ]

  console.log "Writing PGMs..."
  m.write("biden4x.pgm", "biden4y.pgm", "biden4a.pgm")

  console.log "Converting alpha PGM to PNG..."
  run "convert biden4a.pgm -alpha copy -fx '#fff' biden4a.png"

  console.log "Running ffmpeg..."
  run "ffmpeg -y -hide_banner -i clouds.mp4 -i biden4x.pgm -i biden4y.pgm -loop 1 -i biden4a.png -i biden4.png -filter_complex \"[0][1][2]remap[m];[3]alphaextract[a];[m][a]alphamerge[merged];[4][merged]overlay\" output.mp4"

  console.log "Done! Watch: output.mp4"

main()

