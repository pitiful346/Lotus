import 'package:flutter/material.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  List<String> _historicoPesquisas = [];
  List<String> get historicoPesquisas => _historicoPesquisas;
  set historicoPesquisas(List<String> value) {
    _historicoPesquisas = value;
  }

  void addToHistoricoPesquisas(String value) {
    historicoPesquisas.add(value);
  }

  void removeFromHistoricoPesquisas(String value) {
    historicoPesquisas.remove(value);
  }

  void removeAtIndexFromHistoricoPesquisas(int index) {
    historicoPesquisas.removeAt(index);
  }

  void updateHistoricoPesquisasAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    historicoPesquisas[index] = updateFn(_historicoPesquisas[index]);
  }

  void insertAtIndexInHistoricoPesquisas(int index, String value) {
    historicoPesquisas.insert(index, value);
  }

  String _filtroPrecoGlobal = '';
  String get filtroPrecoGlobal => _filtroPrecoGlobal;
  set filtroPrecoGlobal(String value) {
    _filtroPrecoGlobal = value;
  }

  String _filtroDataGlobal = '';
  String get filtroDataGlobal => _filtroDataGlobal;
  set filtroDataGlobal(String value) {
    _filtroDataGlobal = value;
  }

  int _filtroCidadeGlobal = 0;
  int get filtroCidadeGlobal => _filtroCidadeGlobal;
  set filtroCidadeGlobal(int value) {
    _filtroCidadeGlobal = value;
  }

  String _filtroStatusGlobal = '';
  String get filtroStatusGlobal => _filtroStatusGlobal;
  set filtroStatusGlobal(String value) {
    _filtroStatusGlobal = value;
  }

  double _precoMinGlobal = 0.0;
  double get precoMinGlobal => _precoMinGlobal;
  set precoMinGlobal(double value) {
    _precoMinGlobal = value;
  }

  double _precoMaxGlobal = 0.0;
  double get precoMaxGlobal => _precoMaxGlobal;
  set precoMaxGlobal(double value) {
    _precoMaxGlobal = value;
  }

  String _filtroCategoriaGlobal = '';
  String get filtroCategoriaGlobal => _filtroCategoriaGlobal;
  set filtroCategoriaGlobal(String value) {
    _filtroCategoriaGlobal = value;
  }
}
