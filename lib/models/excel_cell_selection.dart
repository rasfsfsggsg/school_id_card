class ExcelCellSelection {
  final int row;
  final int col;
  final String value;
  final String address; // A1, B4 etc

  ExcelCellSelection({
    required this.row,
    required this.col,
    required this.value,
    required this.address,
  });
}
