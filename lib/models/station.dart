class Station {
  final String id;
  final String name;

  const Station({
    required this.id,
    required this.name,
  });

  static const List<Station> popularStations = [
    Station(id: '900100003', name: 'S+U Alexanderplatz'),
    Station(id: '900003201', name: 'S+U Berlin Hauptbahnhof'),
    Station(id: '900017101', name: 'U Mehringdamm'),
    Station(id: '900100001', name: 'S+U Friedrichstr.'),
    Station(id: '900120005', name: 'S Ostbahnhof'),
    Station(id: '900023201', name: 'S+U Zoologischer Garten'),
    Station(id: '900007102', name: 'S+U Gesundbrunnen'),
    Station(id: '900029101', name: 'S Berlin-Spandau'),
    Station(id: '900058101', name: 'S Südkreuz'),
    Station(id: '900160004', name: 'S Lichtenberg'),
  ];

  static Station get defaultStation => popularStations[0];
}
