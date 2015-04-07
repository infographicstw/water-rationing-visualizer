require! <[fs]>

rationing-list = fs.read-file-sync \list.csv .toString! .split \\n 
rationing-list = rationing-list.slice(1, rationing-list.length).filter(-> it).map -> it.split \,

topojson = do
  village: JSON.parse(fs.read-file-sync \village.json .toString!)
  town: JSON.parse(fs.read-file-sync \town.json .toString!)

geoblock = do
  village: topojson.village.objects["10402村里界(WGS84經緯度)"].geometries
  town: topojson.town.objects["鄉鎮界(經緯度)1031225_big5"].geometries

usedblock = village: [], town: []

hash = {}
for rule in rationing-list => 
  if rule.1 == \_ =>
    for geo in geoblock.town => if geo.properties.C_Name == rule.0 =>
      hash{}["#{rule.0}/#{geo.properties.T_Name}"]["_"] = rule
  else =>hash{}["#{rule.0}/#{rule.1}"][rule.2] = rule

town-only = [k for k of hash]filter -> [k for k of hash[it]].length == 1 and hash[it][\_]
console.log town-only
have-village = [k for k of hash]filter -> [k for k of hash[it]].length > 1 or !hash[it][\_]
console.log ">>>", have-village
for geo in geoblock.town =>
  p = geo.properties
  key = "#{p.C_Name}/#{p.T_Name}"
  if town-only.indexOf(key) >= 0 =>
    p.category = hash[key]["_"].3
    if hash[key]["_"].4 => p.[]comment.push that
    usedblock.town.push geo
for geo in geoblock.village =>
  p = geo.properties
  key = "#{p.C_Name}/#{p.T_Name}"
  if have-village.indexOf(key) >= 0 =>
    datasrc = if hash[key][p.V_Name] => that else hash[key]["_"]
    if !datasrc => continue
    p.category = datasrc.3
    if datasrc.4 => p.[]comment.push that
    usedblock.village.push geo

topojson.village.objects["10402村里界(WGS84經緯度)"].geometries = usedblock.village
topojson.town.objects["鄉鎮界(經緯度)1031225_big5"].geometries = usedblock.town

fs.write-file-sync \geodata.json, JSON.stringify(topojson)
