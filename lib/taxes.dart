import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:csv/csv.dart';

class PantallaTaxes extends StatefulWidget {
  final List<Map<String, dynamic>> rutas;

  PantallaTaxes({required this.rutas});

  @override
  _PantallaTaxesState createState() => _PantallaTaxesState();
}

class _PantallaTaxesState extends State<PantallaTaxes> {
  List<List<String>> datosTabla = List.generate(3, (index) => List.filled(7, ''));
  List<List<TextEditingController>> controladores =
  List.generate(3, (i) => List.generate(7, (j) => TextEditingController()));

  Map<String, double> totales = {
    'totalPago': 0.0,
    'totalTaxes': 0.0,
    'totalMillas': 0.0,
    'totalRodamiento': 0.0,
    'pagoNeto': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
    _cargarUltimosDatos();
    _limpiarDatosInvalidos(); // Nueva función añadida
  }

  bool _esFormatoFechaValido(String fechaKey) {
    try {
      final partes = fechaKey.split(" - ");
      if (partes.length != 2) return false;

      final fechaInicio = DateFormat('dd/MM/yyyy').parse(partes[0]);
      final fechaFin = DateFormat('dd/MM/yyyy').parse(partes[1]);

      return fechaInicio.isBefore(fechaFin) || fechaInicio.isAtSameMomentAs(fechaFin);
    } catch (e) {
      return false;
    }
  }

  Future<void> _limpiarDatosInvalidos() async {
    final prefs = await SharedPreferences.getInstance();
    final todasLasClaves = prefs.getKeys();

    for (var clave in todasLasClaves) {
      if (clave.startsWith('taxes_') && !clave.contains('ultima_semana')) {
        if (!_esFormatoFechaValido(clave.replaceFirst('taxes_', ''))) {
          await prefs.remove(clave);
        }
      }
    }
  }

  void _inicializarDatos() {
    datosTabla[0][0] = "Rutas";
    datosTabla[1][0] = "Uber";
    datosTabla[2][0] = "Lyft";

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 7; j++) {
        controladores[i][j].text = datosTabla[i][j];
      }
    }
    _calcularTotales();
  }

  void _cargarUltimosDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimaSemana = prefs.getString('taxes_ultima_semana');

    if (ultimaSemana != null && _esFormatoFechaValido(ultimaSemana)) {
      final datosJson = prefs.getString('taxes_$ultimaSemana');
      if (datosJson != null) {
        final datosDecoded = jsonDecode(datosJson) as List<dynamic>;
        setState(() {
          for (int i = 0; i < datosDecoded.length; i++) {
            for (int j = 0; j < 7; j++) {
              controladores[i][j].text = datosDecoded[i][j];
            }
          }
          _calcularTotales();
        });
      }
    }
  }

  void _agregarFila() {
    setState(() {
      datosTabla.add(List.filled(7, ''));
      controladores.add(List.generate(7, (j) => TextEditingController()));
    });
  }

  void _eliminarFila(int indice) {
    setState(() {
      if (datosTabla.length > 3) {
        datosTabla.removeAt(indice);
        controladores.removeAt(indice);
        _calcularTotales();
      }
    });
  }

  double _calcularImpuestos(double pago, double millas) {
    const tasaImpuestoFederal = 0.22;
    const tasaImpuestoEstatal = 0.0495;
    const tasaAutonomo = 0.153;
    const deduccionMillaje = 0.655;

    double ingresosNetos = pago - (millas * deduccionMillaje);
    double impuestoAutonomo = ingresosNetos * tasaAutonomo;
    double impuestoFederal = ingresosNetos * tasaImpuestoFederal;
    double impuestoEstatal = ingresosNetos * tasaImpuestoEstatal;

    return impuestoAutonomo + impuestoFederal + impuestoEstatal;
  }

  void _calcularTotales() {
    double totalPago = 0.0;
    double totalTaxes = 0.0;
    double totalMillas = 0.0;
    double totalRodamiento = 0.0;

    for (int i = 0; i < datosTabla.length; i++) {
      totalPago += double.tryParse(controladores[i][1].text) ?? 0.0;
      totalMillas += double.tryParse(controladores[i][2].text) ?? 0.0;
      totalTaxes += double.tryParse(controladores[i][3].text) ?? 0.0;
      totalRodamiento += double.tryParse(controladores[i][5].text) ?? 0.0;
    }

    double pagoNeto = totalPago - (totalTaxes + totalRodamiento);

    setState(() {
      totales['totalPago'] = totalPago;
      totales['totalTaxes'] = totalTaxes;
      totales['totalMillas'] = totalMillas;
      totales['totalRodamiento'] = totalRodamiento;
      totales['pagoNeto'] = pagoNeto;
    });
  }

  void _calcularValoresAutomaticos() {
    for (int i = 0; i < datosTabla.length; i++) {
      final pago = double.tryParse(controladores[i][1].text) ?? 0.0;
      final millas = double.tryParse(controladores[i][2].text) ?? 0.0;
      final taxes = _calcularImpuestos(pago, millas);
      final rodamiento = pago * 0.02;

      if (pago > 0) {
        controladores[i][3].text = taxes.toStringAsFixed(2);
        controladores[i][5].text = rodamiento.toStringAsFixed(2);
      } else {
        controladores[i][3].text = "";
        controladores[i][5].text = "";
      }
    }
    _calcularTotales();
  }

  void _guardarDatos() async {
    final anioSeleccionado = await _seleccionarAnio();
    if (anioSeleccionado == null) return;

    final mesSeleccionado = await _seleccionarMes();
    if (mesSeleccionado == null) return;

    final semanaSeleccionada = await _seleccionarSemana(anioSeleccionado, mesSeleccionado);
    if (semanaSeleccionada == null) return;

    final prefs = await SharedPreferences.getInstance();
    final datosGuardados = [];

    for (int i = 0; i < datosTabla.length; i++) {
      List<String> fila = [];
      for (int j = 0; j < 7; j++) {
        fila.add(controladores[i][j].text);
      }
      datosGuardados.add(fila);
    }

    final clave = 'taxes_$semanaSeleccionada';
    prefs.setString(clave, jsonEncode(datosGuardados));
    prefs.setString('taxes_ultima_semana', semanaSeleccionada);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Datos guardados para la semana: $semanaSeleccionada")),
    );
  }

  Future<String?> _seleccionarSemana(int anio, int mes) async {
    final semanas = _obtenerSemanasDelMes(anio, mes);
    final semanaSeleccionada = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Seleccione la semana"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: semanas.map((semana) {
                return ListTile(
                  title: Text(semana),
                  onTap: () => Navigator.pop(context, semana),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    return semanaSeleccionada;
  }

  List<String> _obtenerSemanasDelMes(int anio, int mes) {
    final semanas = <String>[];
    final primerDiaDelMes = DateTime(anio, mes, 1);
    final ultimoDiaDelMes = DateTime(anio, mes + 1, 0);

    DateTime inicioSemana = primerDiaDelMes;
    while (inicioSemana.isBefore(ultimoDiaDelMes) || inicioSemana.isAtSameMomentAs(ultimoDiaDelMes)) {
      DateTime finSemana = inicioSemana.add(Duration(days: 6)); // Cambiado a var/DateTime
      if (finSemana.month != mes) {
        finSemana = ultimoDiaDelMes; // Ahora podemos reasignar
      }
      semanas.add("${DateFormat('dd/MM/yyyy').format(inicioSemana)} - ${DateFormat('dd/MM/yyyy').format(finSemana)}");
      inicioSemana = inicioSemana.add(Duration(days: 7));
    }

    return semanas;
  }

  Future<int?> _seleccionarMes() async {
    final ahora = DateTime.now();
    int? mesSeleccionado;

    await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Seleccione el mes"),
          content: DropdownButton<int>(
            value: mesSeleccionado,
            items: List.generate(12, (index) {
              return DropdownMenuItem<int>(
                value: index + 1,
                child: Text(DateFormat('MMMM').format(DateTime(ahora.year, index + 1))),
              );
            }),
            onChanged: (value) {
              setState(() {
                mesSeleccionado = value;
              });
              Navigator.pop(context, value);
            },
          ),
        );
      },
    );

    return mesSeleccionado;
  }

  Future<int?> _seleccionarAnio() async {
    int? anioSeleccionado;

    await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Seleccione el año"),
          content: DropdownButton<int>(
            value: anioSeleccionado,
            items: List.generate(27, (index) {
              return DropdownMenuItem<int>(
                value: 2024 + index,
                child: Text((2024 + index).toString()),
              );
            }),
            onChanged: (value) {
              setState(() {
                anioSeleccionado = value;
              });
              Navigator.pop(context, value);
            },
          ),
        );
      },
    );

    return anioSeleccionado;
  }

  void _exportarDatos() async {
    final tipoArchivo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Seleccione el tipo de archivo"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Excel (.xlsx)"),
                onTap: () => Navigator.pop(context, 'excel'),
              ),
              ListTile(
                title: Text("CSV (.csv)"),
                onTap: () => Navigator.pop(context, 'csv'),
              ),
            ],
          ),
        );
      },
    );

    if (tipoArchivo == null) return;

    List<List<String>> exportData = [];
    exportData.add(["App", "Pago", "Millas", "Taxes", "Peajes", "Rodamiento", "Otros"]);

    for (int i = 0; i < datosTabla.length; i++) {
      List<String> fila = [];
      for (int j = 0; j < 7; j++) {
        fila.add(controladores[i][j].text);
      }
      exportData.add(fila);
    }

    Directory directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/estados_de_cuenta.${tipoArchivo == 'excel' ? 'xlsx' : 'csv'}';

    if (tipoArchivo == 'excel') {
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];

      sheet.getRangeByName('A1').setText('App');
      sheet.getRangeByName('B1').setText('Pago');
      sheet.getRangeByName('C1').setText('Millas');
      sheet.getRangeByName('D1').setText('Taxes');
      sheet.getRangeByName('E1').setText('Peajes');
      sheet.getRangeByName('F1').setText('Rodamiento');
      sheet.getRangeByName('G1').setText('Otros');

      for (var i = 0; i < exportData.length; i++) {
        for (var j = 0; j < exportData[i].length; j++) {
          sheet.getRangeByIndex(i + 1, j + 1).setText(exportData[i][j]);
        }
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      File file = File(filePath);
      await file.writeAsBytes(bytes);
    } else {
      String csvData = const ListToCsvConverter().convert(exportData);
      File file = File(filePath);
      await file.writeAsString(csvData);
    }

    Share.shareXFiles([XFile(filePath)], text: 'Estados de cuenta de la semana');
  }

  void _verDatosPorPeriodo() async {
    final prefs = await SharedPreferences.getInstance();
    final todasLasSemanas = prefs.getKeys()
        .where((key) => key.startsWith('taxes_') && !key.contains('ultima_semana'))
        .toList();

    // Seleccionar año
    final anioSeleccionado = await _seleccionarAnio();
    if (anioSeleccionado == null) return;

    // Seleccionar "Todo" o un mes específico
    final opcionMes = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Seleccione una opción"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Todo el año"),
                onTap: () => Navigator.pop(context, 'todo'),
              ),
              ListTile(
                title: Text("Seleccionar mes"),
                onTap: () => Navigator.pop(context, 'mes'),
              ),
            ],
          ),
        );
      },
    );

    if (opcionMes == null) return;

    List<String> semanasFiltradas = [];

    if (opcionMes == 'todo') {
      // Filtrar semanas del año seleccionado con validación de formato
      semanasFiltradas = todasLasSemanas.where((semanaKey) {
        try {
          final fechaStr = semanaKey.replaceFirst('taxes_', '').split(" - ")[0];
          final fecha = DateFormat('dd/MM/yyyy').parse(fechaStr);
          return fecha.year == anioSeleccionado;
        } catch (e) {
          return false;
        }
      }).toList();
    } else {
      // Seleccionar mes
      final mesSeleccionado = await _seleccionarMes();
      if (mesSeleccionado == null) return;

      // Seleccionar "Todo" o una semana específica
      final opcionSemana = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Seleccione una opción"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text("Todo el mes"),
                  onTap: () => Navigator.pop(context, 'todo'),
                ),
                ListTile(
                  title: Text("Seleccionar semana"),
                  onTap: () => Navigator.pop(context, 'semana'),
                ),
              ],
            ),
          );
        },
      );

      if (opcionSemana == null) return;

      if (opcionSemana == 'todo') {
        // Filtrar semanas del mes seleccionado con validación de formato
        semanasFiltradas = todasLasSemanas.where((semanaKey) {
          try {
            final fechaStr = semanaKey.replaceFirst('taxes_', '').split(" - ")[0];
            final fecha = DateFormat('dd/MM/yyyy').parse(fechaStr);
            return fecha.year == anioSeleccionado && fecha.month == mesSeleccionado;
          } catch (e) {
            return false;
          }
        }).toList();
      } else {
        // Seleccionar semana específica
        final semanaSeleccionada = await _seleccionarSemana(anioSeleccionado, mesSeleccionado);
        if (semanaSeleccionada == null) return;

        semanasFiltradas = ['taxes_$semanaSeleccionada'];
      }
    }

    // Calcular y mostrar el resumen
    if (semanasFiltradas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No hay datos para este período")),
      );
      setState(() {
        for (int i = 0; i < datosTabla.length; i++) {
          for (int j = 0; j < 7; j++) {
            controladores[i][j].text = "";
          }
        }
        _calcularTotales();
      });
    } else {
      final resumen = _calcularResumenPeriodo(semanasFiltradas, prefs);
      _mostrarResumenPeriodo(resumen);
    }
  }

  Map<String, List<double>> _calcularResumenPeriodo(List<String> semanas, SharedPreferences prefs) {
    final resumen = <String, List<double>>{};

    for (var semana in semanas) {
      final datos = jsonDecode(prefs.getString(semana)!) as List<dynamic>;
      for (var fila in datos) {
        final app = fila[0];
        if (!resumen.containsKey(app)) {
          resumen[app] = List.filled(7, 0.0);
        }
        for (var j = 1; j < 7; j++) {
          resumen[app]![j] += double.tryParse(fila[j]) ?? 0.0;
        }
      }
    }

    return resumen;
  }

  void _mostrarResumenPeriodo(Map<String, List<double>> resumen) {
    setState(() {
      // Limpiar la tabla
      for (int i = 0; i < datosTabla.length; i++) {
        for (int j = 0; j < 7; j++) {
          controladores[i][j].text = "";
        }
      }

      // Llenar con los datos del resumen
      int i = 0;
      resumen.forEach((app, valores) {
        // Asegurarse de que hay suficientes filas
        if (i >= datosTabla.length) {
          datosTabla.add(List.filled(7, ''));
          controladores.add(List.generate(7, (j) => TextEditingController()));
        }

        controladores[i][0].text = app;
        for (int j = 1; j < 7; j++) {
          controladores[i][j].text = valores[j].toStringAsFixed(2);
        }
        i++;
      });

      _calcularTotales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("TAXES"),
            Text("Jorge Charrupi", style: TextStyle(fontSize: 14)),
          ],
        ),
        backgroundColor: Colors.greenAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder.all(),
                    defaultColumnWidth: FixedColumnWidth(100.0),
                    children: [
                      TableRow(
                        children: ["App", "Pago", "Millas", "Taxes", "Peajes", "Rodamiento", "Otros", "Acción"]
                            .map((e) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(e, style: TextStyle(fontWeight: FontWeight.bold)),
                        ))
                            .toList(),
                      ),
                      for (int i = 0; i < datosTabla.length; i++)
                        TableRow(
                          children: [
                            for (int j = 0; j < 7; j++)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  controller: controladores[i][j],
                                  onChanged: (value) {
                                    if (j == 1 || j == 2) {
                                      _calcularValoresAutomaticos();
                                    }
                                    _calcularTotales();
                                  },
                                  decoration: InputDecoration(border: InputBorder.none),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarFila(i),
                            ),
                          ],
                        ),
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Totales", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(totales['totalPago']?.toStringAsFixed(2) ?? "0.00"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(totales['totalMillas']?.toStringAsFixed(2) ?? "0.00"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(totales['totalTaxes']?.toStringAsFixed(2) ?? "0.00"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(""),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(totales['totalRodamiento']?.toStringAsFixed(2) ?? "0.00"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(""),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(""),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text("Total Pago: \$${totales['totalPago']?.toStringAsFixed(2) ?? "0.00"}"),
            Text("Total Millas: ${totales['totalMillas']?.toStringAsFixed(2) ?? "0.00"} millas"),
            Text(
                "Total Taxes + Rodamiento: \$${((totales['totalTaxes'] ?? 0.0) + (totales['totalRodamiento'] ?? 0.0)).toStringAsFixed(2)}"
            ),
            Text(
                "Pago Neto: \$${totales['pagoNeto']?.toStringAsFixed(2) ?? "0.00"}"
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _agregarFila,
                    child: Text("Agregar Fila"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _guardarDatos,
                    child: Text("Guardar"),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _exportarDatos,
                    child: Text("Exportar"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _verDatosPorPeriodo,
                    child: Text("Ver datos"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}