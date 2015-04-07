angular.module \main, <[]>
  ..controller \main, <[$scope $http]> ++ ($scope, $http) ->
    $scope.target = {name:'新北市三峽區安坑里'}
    $scope.open-widget = -> $scope.toggle-widget = !!!$scope.toggle-widget
    console.log "loading..."
    #(csv) <- d3.csv \list-old.csv, _
    #hash = {}
    #for item in csv => hash["#{item.county}/#{item.town}/#{item.village}"] = item
    #(topo) <- d3.json \village-sm.json, _
    (topo) <- d3.json \geodata.json, _
    $scope.topo = topo
    features = do
      village: topojson.feature(topo.village, topo.village.objects["10402村里界(WGS84經緯度)"]).features
      town:  topojson.feature(topo.town, topo.town.objects["鄉鎮界(經緯度)1031225_big5"]).features
    features.all = features.village ++ features.town

    $scope.projection = projection = d3.geo.mercator!center([121.553243, 24.926172]).scale 50000
    path = d3.geo.path!projection projection
    typehash = do
      3: "週五、週六限水"
      1: "週一、週二限水"
      2: "週三、週四限水"
    settype = -> 
      $scope.target.type = typehash[it]

    mouse-event = (block)-> $scope.$apply ->
      p = block.properties
      $scope.target.name = "#{p.C_Name}#{p.T_Name}#{p.V_Name or ''}"
      settype p.category
      $scope.target.comment = (p.comment or []).join " / "

    d3.select 'svg g#geoblock' .selectAll \path .data features.all .enter!append \path
    d3.select 'svg g#clickblock' .selectAll \path .data features.all .enter!append \path

    render = (selection,click=false) ->
      selection
        ..style do
          cursor: \pointer
        ..attr do
          d: path
          opacity: -> if click => \0.01 else 1
          fill: ->
            if it.properties.category == \3 => return \#802e23
            if it.properties.category == \1 => return \#48762e
            if it.properties.category == \2 => return \#b5878b
            return \#999
          stroke: ->
            if it.properties.category == \3 => return \#a04e43
            if it.properties.category == \1 => return \#68964e
            if it.properties.category == \2 => return \#d5a7ab
        ..on \click, mouse-event
        ..on \mousemove, mouse-event

    render(d3.select 'svg g#geoblock' .selectAll \path)
    render(d3.select('svg g#clickblock').selectAll(\path),true)

    $scope.goto = ->
      geocoder = new google.maps.Geocoder()
      geocoder.geocode {'address': $scope.address}, (result, status) ->
        if status == google.maps.GeocoderStatus.OK =>
          loc = result[0].geometry.location |> -> [it.lng!, it.lat!]
          [x,y] = $scope.projection loc
          d3.select \#marker .transition!duration 300 .attr do
            x: x - 16
            y: y - 45
      $scope.toggle-widget = false
    [x,y] = $scope.projection [121.480705,25.038353]
    [x2,y2] = $scope.projection [121.485511,24.994486]
    $scope.$apply -> $scope.m = {x:x,y:y}
    $scope.$apply -> $scope.m2 = {x:x2,y:y2}
    settype 1
