// part: roads
[out:json][timeout:180];
(
  way["highway"~"^(motorway|trunk|primary|secondary|tertiary)(_link)?$"](39.7134570,-105.0927200,39.7832661,-104.9970497);
  way["highway"~"^(unclassified|residential|living_street)$"](39.7134570,-105.0927200,39.7832661,-104.9970497);
  way["highway"="service"]["service"="alley"](39.7134570,-105.0927200,39.7832661,-104.9970497);
);
(._;>;);
out body qt;

// part: linear
[out:json][timeout:180];
relation["type"="multipolygon"]["natural"="water"](39.7134570,-105.0927200,39.7832661,-104.9970497)(if: count_members() >= 300)->.bigwater;
(
  way["railway"~"^(rail|light_rail|subway|tram|narrow_gauge|monorail)$"](39.7134570,-105.0927200,39.7832661,-104.9970497);
  way["natural"="coastline"](39.7134570,-105.0927200,39.7832661,-104.9970497);
  way["natural"="water"](39.7134570,-105.0927200,39.7832661,-104.9970497);
  relation["type"="multipolygon"]["natural"="water"](39.7134570,-105.0927200,39.7832661,-104.9970497)(if: count_members() < 300);
  way["waterway"~"^(river|canal|stream)$"](39.7134570,-105.0927200,39.7832661,-104.9970497);
);
(._;>;);
out body qt;
.bigwater out body qt;
way(r.bigwater)(39.7134570,-105.0927200,39.7832661,-104.9970497);
(._;>;);
out body qt;

// part: areas
[out:json][timeout:180];
(
  way["landuse"]["landuse"!="grass"](39.7134570,-105.0927200,39.7832661,-104.9970497);
  way["landuse"="grass"](39.7134570,-105.0927200,39.7832661,-104.9970497)(if: length() >= 200);
  way["natural"~"^(wood|scrub|grassland|wetland|beach|sand)$"](39.7134570,-105.0927200,39.7832661,-104.9970497);
  way["leisure"~"^(park|golf_course|pitch|playground|garden|nature_reserve|recreation_ground)$"](39.7134570,-105.0927200,39.7832661,-104.9970497);
  way["amenity"="grave_yard"](39.7134570,-105.0927200,39.7832661,-104.9970497);
  relation["type"="multipolygon"]["landuse"](39.7134570,-105.0927200,39.7832661,-104.9970497)(if: count_members() < 300);
  relation["type"="multipolygon"]["natural"~"^(wood|scrub|grassland|wetland|beach|sand)$"](39.7134570,-105.0927200,39.7832661,-104.9970497)(if: count_members() < 300);
  relation["type"="multipolygon"]["leisure"~"^(park|golf_course|pitch|playground|garden|nature_reserve|recreation_ground)$"](39.7134570,-105.0927200,39.7832661,-104.9970497)(if: count_members() < 300);
  relation["type"="multipolygon"]["amenity"="grave_yard"](39.7134570,-105.0927200,39.7832661,-104.9970497)(if: count_members() < 300);
);
(._;>;);
out body qt;

// part: buildings
[out:json][timeout:180];
(
  way["building"](39.7359819,-105.0635714,39.7607580,-105.0262399);
  relation["building"]["type"="multipolygon"](39.7359819,-105.0635714,39.7607580,-105.0262399)(if: count_members() < 300);
);
(._;>;);
out body qt;
