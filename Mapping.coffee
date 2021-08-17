fs = require 'fs'

class Mapping
  constructor: (@w, @h, @vw = 0, @vh = 0) ->
    # w/h are destination map size, vw/vh are source video size
    if @vw < 1
      @vw = @w
    if @vh < 1
      @vh = @h
    @total = @w * @h
    @map = new Array(@total)
    for i in [0...@total]
      @map[i] =
        x: 0
        y: 0
        a: 0

  project: (coords) ->

    # Scanlines
    rows = new Array(@h)
    for y in [0...@h]
      rows[y] =
        min: @w
        minUV: null
        max: 0
        maxUV: null
    lines = [
      [ coords[0], coords[1], coords[2], coords[3] ] # top
      [ coords[6], coords[7], coords[4], coords[5] ] # bottom
      [ coords[0], coords[1], coords[6], coords[7] ] # left
      [ coords[2], coords[3], coords[4], coords[5] ] # right
    ]
    for lineIndex in [0...4]
      line = lines[lineIndex]
      x0Start = line[0]
      y0Start = line[1]
      x1Start = line[2]
      y1Start = line[3]
      x0 = x0Start
      y0 = y0Start
      x1 = x1Start
      y1 = y1Start
      # console.log "testing (#{x0}, #{y0}) -> (#{x1}, #{y1})"
      dx = Math.abs(x1 - x0)
      sx = if x0 < x1 then 1 else -1
      dy = Math.abs(y1 - y0)
      sy = if y0 < y1 then 1 else -1
      err = (if dx>dy then dx else -dy) / 2
      points = []
      loop
        points.push [x0, y0]
        break if x0 == x1 && y0 == y1
        e2 = err
        if e2 > -dx
          err -= dy
          x0 += sx
        if e2 < dy
          err += dx
          y0 += sy

      plast = points.length - 1
      for p, pointIndex in points
        x = p[0]
        y = p[1]
        switch lineIndex
          when 0 # top
            u = Math.floor((@vw - 1) * pointIndex / plast)
            v = 0
          when 1 # bottom
            u = Math.floor((@vw - 1) * pointIndex / plast)
            v = @vh - 1
          when 2 # left
            u = 0
            v = Math.floor((@vh - 1) * pointIndex / plast)
          when 3 # right
            u = @vw - 1
            v = Math.floor((@vh - 1) * pointIndex / plast)
        if rows[y].min > x
          rows[y].min = x
          rows[y].minUV = [u, v]
        if rows[y].max < x
          rows[y].max = x
          rows[y].maxUV = [u, v]

    # UV mapping
    for y in [0...@h]
      row = rows[y]
      if (row.max < row.min) or not row.minUV? or not row.maxUV?
        continue
      xindex = 0
      xlast = Math.max(row.max - row.min, 1)
      for x in [row.min..row.max]
        p = xindex / xlast
        e = @map[x + (y * @w)]
        e.x = Math.floor(row.minUV[0] + ((row.maxUV[0] - row.minUV[0]) * p))
        e.y = Math.floor(row.minUV[1] + ((row.maxUV[1] - row.minUV[1]) * p))
        e.a = 65535

        # console.log "(#{row.minUV[0]},#{row.minUV[1]}) --- #{p.toFixed(2)} ---> (#{row.maxUV[0]},#{row.maxUV[1]}) = (#{e.x}, #{e.y})"
        xindex += 1

  write: (xmapFilename, ymapFilename, alphaFilename) ->
    xmap = ymap = alpha = "P2\n#{@w} #{@h}\n65535\n"
    
    debug = 1
    for y in [0...@h]
      for x in [0...@w]
        coord = @map[x + (y * @w)]
        xmap += "#{debug * coord.x} "
        ymap += "#{debug * coord.y} "
        alpha += "#{debug * coord.a} "
      xmap += "\n"
      ymap += "\n"
      alpha += "\n"

    fs.writeFileSync(xmapFilename, xmap)
    fs.writeFileSync(ymapFilename, ymap)
    fs.writeFileSync(alphaFilename, alpha)

module.exports = Mapping

