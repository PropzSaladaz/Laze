class OperativeSystem {
  final String name;
  final int mask;

  const OperativeSystem({required this.name, required this.mask});
}

// ignore: constant_identifier_names
const List<OperativeSystem> SUPPORTED_OSES = [
  OperativeSystem(name: "windows", mask: 1 << 0),
  OperativeSystem(name: "linux", mask: 1 << 1),
  OperativeSystem(name: "macOS", mask: 1 << 2),
];