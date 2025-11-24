enum TransportType {
  regional('Regional', 'RE/RB'),
  sBahn('S-Bahn', 'S'),
  uBahn('U-Bahn', 'U'),
  bus('Bus', 'Bus');

  final String name;
  final String shortName;

  const TransportType(this.name, this.shortName);
}
