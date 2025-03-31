import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para el formato de moneda
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PantallaRutas extends StatefulWidget {
  @override
  _PantallaRutasState createState() => _PantallaRutasState();
}

class _PantallaRutasState extends State<PantallaRutas> {
  // Controladores para los campos de entrada
  TextEditingController galonesMillaController = TextEditingController();
  TextEditingController valorGalonController = TextEditingController();
  TextEditingController millasRutaController = TextEditingController();
  TextEditingController pagoAdicionalController = TextEditingController();
  TextEditingController peajesOtrosController = TextEditingController();

  // Variables para almacenar los valores calculados
  double pagoRutaCalculado = 0.0;
  List<List<String>> datosConsumo = [];
  List<List<TextEditingController>> controladoresConsumo = [];

  // Variables para el cálculo final
  double totalDistancia = 0.0;
  double totalTiempo = 0.0;
  double totalConsumo = 0.0;
  double costoTotal = 0.0;
  double pagoNeto = 0.0;
  double pagoPorHora = 0.0;
  double totalGalones = 0.0;
  double costoGas = 0.0;

  @override
  void initState() {
    super.initState();
    _inicializarDatosConsumo();
  }

  // Inicializar datosConsumo y controladoresConsumo
  void _inicializarDatosConsumo() {
    datosConsumo = List.generate(4, (index) => List.filled(4, ''));
    controladoresConsumo = List.generate(4, (i) => List.generate(2, (j) => TextEditingController()));
  }

  // Método para formatear valores como moneda
  String _formatoMoneda(double valor) {
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return format.format(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("COSTOS RUTAS"),
            Text("Jorge Charrupi", style: TextStyle(fontSize: 14)),
          ],
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Primer cuadro (arriba)
            Text("Datos Generales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.blueAccent, width: 1),
                ),
                columnWidths: {
                  0: FixedColumnWidth(150.0),
                  1: FixedColumnWidth(150.0),
                },
                children: [
                  // Fila 1: Galones/Milla y Valor Galón
                  TableRow(
                    children: [
                      _buildCell("Galones/Milla", galonesMillaController, (value) {
                        _calcularTotales();
                      }, editable: true),
                      _buildCell("Valor Galón", valorGalonController, (value) {
                        _calcularTotales();
                      }, editable: true),
                    ],
                  ),
                  // Fila 2: Millas Ruta y Pago Adicional
                  TableRow(
                    children: [
                      _buildCell("Millas Ruta", millasRutaController, (value) {
                        _calcularPagoRuta();
                        _calcularTotales();
                      }, editable: true),
                      _buildCell("Pago Adicional", pagoAdicionalController, (value) {
                        _calcularPagoRuta();
                        _calcularTotales();
                      }, editable: true),
                    ],
                  ),
                  // Fila 3: Peajes y Otros y Taxes
                  TableRow(
                    children: [
                      _buildCell("Peajes y Otros", peajesOtrosController, (value) {
                        _calcularTotales();
                      }, editable: true),
                      _buildCell("Pago Ruta", null, null, value: _formatoMoneda(pagoRutaCalculado + (double.tryParse(pagoAdicionalController.text) ?? 0.0)), color: Colors.orange[100]),
                    ],
                  ),
                  // Fila 4: Total Galones y Costo Gas
                  TableRow(
                    children: [
                      _buildCell("Total Tiempo", null, null, value: _convertirMinutosAHoras(totalTiempo), color: Colors.lightGreen[200]),
                      _buildCell("Taxes", null, null, value: _formatoMoneda((pagoRutaCalculado + (double.tryParse(pagoAdicionalController.text) ?? 0.0)) * 0.20), color: Colors.deepOrange[100]),
                    ],
                  ),
                  // Fila 5: Pago Ruta y Costo Total
                  TableRow(
                    children: [
                      _buildCell("Total Galones", null, null, value: totalGalones.toStringAsFixed(2), color: Colors.lightGreen[200]),
                      _buildCell("Costo Gas", null, null, value: _formatoMoneda(costoGas), color: Colors.deepOrange[100]),
                    ],
                  ),
                  // Fila 6: Total Millas y Total Tiempo
                  TableRow(
                    children: [
                      _buildCell("Total Millas", null, null, value: totalDistancia.toStringAsFixed(2), color: Colors.lightGreen[200]),
                      _buildCell("Costo Total", null, null, value: _formatoMoneda(costoTotal + (double.tryParse(peajesOtrosController.text) ?? 0.0)), color: Colors.deepOrange[100]),
                    ],
                  ),
                  // Fila 7: Pago Neto y Pago por Hora
                  TableRow(
                    children: [
                      _buildCell("Pago/Hora", null, null, value: _formatoMoneda(pagoPorHora), color: Colors.yellow[200]),
                      _buildCell("Pago Neto", null, null, value: _formatoMoneda(pagoNeto), color: Colors.yellow[200]),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Segundo cuadro (abajo)
            Text("Datos Ruta", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.blueAccent, width: 1),
                ),
                columnWidths: {
                  0: FixedColumnWidth(80.0), // Ajustar ancho de la columna "Destino"
                  1: FixedColumnWidth(70.0), // Millas
                  2: FixedColumnWidth(70.0), // Tiempo
                  3: FixedColumnWidth(70.0), // Galones
                  4: FixedColumnWidth(80.0), // Precio
                },
                children: [
                  TableRow(
                    children: [
                      _buildHeader("Destino"),
                      _buildHeader("Millas"),
                      _buildHeader("Tiempo"),
                      _buildHeader("Galones"),
                      _buildHeader("Precio"),
                    ],
                  ),
                  for (int i = 0; i < datosConsumo.length; i++)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text((i + 1).toString(), textAlign: TextAlign.center),
                        ),
                        _buildTextField(controladoresConsumo[i][0], (value) => _calcularConsumo(i), editable: true),
                        _buildTextField(controladoresConsumo[i][1], (value) => _calcularConsumo(i), editable: true),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(datosConsumo[i][2], textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(_formatoMoneda(double.tryParse(datosConsumo[i][3]) ?? 0.0), textAlign: TextAlign.center),
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
                        child: Text(totalDistancia.toStringAsFixed(2), textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_convertirMinutosAHoras(totalTiempo), textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(totalConsumo.toStringAsFixed(2), textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_formatoMoneda(totalConsumo * (double.tryParse(valorGalonController.text) ?? 0.0)), textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Botones Agregar/Quitar Fila
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _agregarFila,
                  child: Text("Agregar Fila"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[100],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
                ElevatedButton(
                  onPressed: _quitarFila,
                  child: Text("Quitar Fila"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Botones Guardar y Registro
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _guardarDatos,
                  child: Text("Guardar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen[200],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: _mostrarRegistros,
                  child: Text("Registro"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue[200],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir una celda con un campo de texto
  Widget _buildCell(String label, TextEditingController? controller, Function(String)? onChanged, {String? value, bool editable = false, Color? color}) {
    return Container(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            controller != null
                ? TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                filled: true,
                fillColor: editable ? Colors.lightBlue[50] : Colors.grey[200],
              ),
            )
                : Text(value ?? '', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // Método para construir un encabezado
  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // Método para construir un campo de texto
  Widget _buildTextField(TextEditingController controller, Function(String) onChanged, {bool editable = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
          filled: true,
          fillColor: editable ? Colors.lightBlue[50] : Colors.grey[200],
        ),
      ),
    );
  }

  void _calcularPagoRuta() {
    double millasRuta = double.tryParse(millasRutaController.text) ?? 0.0;
    if (millasRuta <= 16) {
      pagoRutaCalculado = 40;
    } else if (millasRuta > 16 && millasRuta <= 25) {
      pagoRutaCalculado = 40 + (millasRuta - 16) * 1.76;
    } else if (millasRuta > 25) {
      pagoRutaCalculado = 40 + (9 * 1.76) + (millasRuta - 25) * 1.36;
    }
    _calcularTotales();
    setState(() {});
  }

  void _calcularConsumo(int index) {
    if (index >= datosConsumo.length || index >= controladoresConsumo.length) return; // Verifica que el índice sea válido

    double distancia = double.tryParse(controladoresConsumo[index][0].text) ?? 0.0;
    double tiempo = double.tryParse(controladoresConsumo[index][1].text) ?? 0.0;
    double galonesMilla = double.tryParse(galonesMillaController.text) ?? 0.0;

    if (galonesMilla > 0) {
      datosConsumo[index][2] = (distancia / galonesMilla).toStringAsFixed(2);
      datosConsumo[index][3] = (double.parse(datosConsumo[index][2]) * (double.tryParse(valorGalonController.text) ?? 0.0)).toStringAsFixed(2);
    } else {
      datosConsumo[index][2] = "0.00";
      datosConsumo[index][3] = "0.00";
    }

    _calcularTotales();
    setState(() {});
  }

  void _calcularTotales() {
    totalDistancia = 0.0;
    totalTiempo = 0.0;
    totalConsumo = 0.0;

    for (int i = 0; i < datosConsumo.length; i++) {
      if (i < controladoresConsumo.length) {
        totalDistancia += double.tryParse(controladoresConsumo[i][0].text) ?? 0.0;
        totalTiempo += double.tryParse(controladoresConsumo[i][1].text) ?? 0.0;
      }
      if (i < datosConsumo.length) {
        totalConsumo += double.tryParse(datosConsumo[i][2]) ?? 0.0;
      }
    }

    double valorGalon = double.tryParse(valorGalonController.text) ?? 0.0;
    costoTotal = totalConsumo * valorGalon;

    double valorFinalPagoRuta = pagoRutaCalculado + (double.tryParse(pagoAdicionalController.text) ?? 0.0);
    double valorFinalTaxes = valorFinalPagoRuta * 0.20;
    double valorFinalCostoTotal = costoTotal + (double.tryParse(peajesOtrosController.text) ?? 0.0);

    pagoNeto = valorFinalPagoRuta - valorFinalCostoTotal - valorFinalTaxes;

    if (totalTiempo > 0) {
      pagoPorHora = pagoNeto / (totalTiempo / 60);
    } else {
      pagoPorHora = 0.0;
    }

    // Calcular Total Galones y Costo Gas
    double galonesMilla = double.tryParse(galonesMillaController.text) ?? 0.0;
    if (galonesMilla > 0) {
      totalGalones = totalDistancia / galonesMilla;
      costoGas = totalGalones * valorGalon;
    } else {
      totalGalones = 0.0;
      costoGas = 0.0;
    }
  }

  // Método para convertir minutos a formato HH:MM
  String _convertirMinutosAHoras(double minutos) {
    int horas = minutos ~/ 60;
    int minutosRestantes = (minutos % 60).toInt();
    return "$horas:${minutosRestantes.toString().padLeft(2, '0')} H";
  }

  // Método para agregar una fila
  void _agregarFila() {
    setState(() {
      datosConsumo.add(List.filled(4, ''));
      controladoresConsumo.add(List.generate(2, (j) => TextEditingController()));
    });
  }

  // Método para quitar una fila
  void _quitarFila() {
    if (datosConsumo.length > 1) {
      setState(() {
        datosConsumo.removeLast();
        controladoresConsumo.removeLast();
      });
      _calcularTotales();
    }
  }

  // Método para guardar los datos
  void _guardarDatos() async {
    final nombreArchivo = await _mostrarDialogoNombreArchivo(context);
    if (nombreArchivo != null && nombreArchivo.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();

      // Calcular el valor de Taxes
      double valorFinalPagoRuta = pagoRutaCalculado + (double.tryParse(pagoAdicionalController.text) ?? 0.0);
      double valorFinalTaxes = valorFinalPagoRuta * 0.20;

      final datos = {
        'galonesMilla': galonesMillaController.text,
        'valorGalon': valorGalonController.text,
        'millasRuta': millasRutaController.text,
        'pagoAdicional': pagoAdicionalController.text,
        'peajesOtros': peajesOtrosController.text,
        'totalDistancia': totalDistancia.toString(),
        'totalTiempo': totalTiempo.toString(),
        'totalConsumo': totalConsumo.toString(),
        'costoTotal': (costoTotal + (double.tryParse(peajesOtrosController.text) ?? 0.0)).toStringAsFixed(2),
        'pagoNeto': pagoNeto.toStringAsFixed(2),
        'pagoPorHora': pagoPorHora.toStringAsFixed(2),
        'pagoRuta': (pagoRutaCalculado + (double.tryParse(pagoAdicionalController.text) ?? 0.0)).toStringAsFixed(2),
        'totalGalones': totalGalones.toStringAsFixed(2),
        'costoGas': costoGas.toStringAsFixed(2),
        'taxes': valorFinalTaxes.toStringAsFixed(2), // Guardar el valor de Taxes
      };

      await prefs.setString('rutas_$nombreArchivo', jsonEncode(datos));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datos guardados correctamente')),
      );
    }
  }

  // Método para mostrar el diálogo de nombre de archivo
  Future<String?> _mostrarDialogoNombreArchivo(BuildContext context) async {
    String? nombreArchivo;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Guardar archivo'),
          content: TextField(
            onChanged: (value) {
              nombreArchivo = value;
            },
            decoration: InputDecoration(hintText: "Nombre del archivo"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
    return nombreArchivo;
  }

  // Método para mostrar los registros guardados
  void _mostrarRegistros() async {
    final prefs = await SharedPreferences.getInstance();
    final archivos = prefs.getKeys().where((key) => key.startsWith('rutas_')).toList();

    if (archivos.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Registros guardados'),
            content: SingleChildScrollView(
              child: Column(
                children: archivos.map((archivo) {
                  return ListTile(
                    title: Text(archivo.replaceFirst('rutas_', '')),
                    onTap: () {
                      Navigator.of(context).pop();
                      _mostrarDatosArchivo(archivo);
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay registros guardados')),
      );
    }
  }

  // Método para mostrar los datos de un archivo
  void _mostrarDatosArchivo(String nombreArchivo) async {
    final prefs = await SharedPreferences.getInstance();
    final datos = prefs.getString(nombreArchivo);
    if (datos != null) {
      final datosMap = jsonDecode(datos);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PantallaRegistro(
            datos: datosMap,
            nombreArchivo: nombreArchivo.replaceFirst('rutas_', ''),
          ),
        ),
      );
    }
  }
}

class PantallaRegistro extends StatelessWidget {
  final Map<String, dynamic> datos;
  final String nombreArchivo;

  PantallaRegistro({required this.datos, required this.nombreArchivo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombreArchivo),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('rutas_$nombreArchivo');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Primer cuadro (arriba)
            Text("Datos Generales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.blueAccent, width: 1),
                ),
                columnWidths: {
                  0: FixedColumnWidth(150.0),
                  1: FixedColumnWidth(150.0),
                },
                children: [
                  // Fila 1: Galones/Milla y Valor Galón
                  TableRow(
                    children: [
                      _buildCell("Galones/Milla", datos['galonesMilla']),
                      _buildCell("Valor Galón", datos['valorGalon']),
                    ],
                  ),
                  // Fila 2: Millas Ruta y Pago Adicional
                  TableRow(
                    children: [
                      _buildCell("Millas Ruta", datos['millasRuta']),
                      _buildCell("Pago Adicional", datos['pagoAdicional']),
                    ],
                  ),
                  // Fila 3: Peajes y Otros y Taxes
                  TableRow(
                    children: [
                      _buildCell("Peajes y Otros", datos['peajesOtros']),
                      _buildCell("Taxes", datos['taxes']), // Mostrar Taxes
                    ],
                  ),
                  // Fila 4: Total Galones y Costo Gas
                  TableRow(
                    children: [
                      _buildCell("Total Galones", datos['totalGalones']),
                      _buildCell("Costo Gas", datos['costoGas']),
                    ],
                  ),
                  // Fila 5: Pago Ruta y Costo Total
                  TableRow(
                    children: [
                      _buildCell("Pago Ruta", datos['pagoRuta']),
                      _buildCell("Costo Total", datos['costoTotal']),
                    ],
                  ),
                  // Fila 6: Total Millas y Total Tiempo
                  TableRow(
                    children: [
                      _buildCell("Total Millas", datos['totalDistancia']),
                      _buildCell("Total Tiempo", _convertirMinutosAHoras(double.tryParse(datos['totalTiempo'].toString()) ?? 0.0)),
                    ],
                  ),
                  // Fila 7: Pago Neto y Pago por Hora
                  TableRow(
                    children: [
                      _buildCell("Pago Neto", datos['pagoNeto']),
                      _buildCell("Pago/Hora", datos['pagoPorHora']),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir una celda con un campo de texto
  Widget _buildCell(String label, dynamic value) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(value?.toString() ?? 'N/A', style: TextStyle(fontSize: 16)), // Mostrar 'N/A' si el valor es null
          ],
        ),
      ),
    );
  }

  // Método para convertir minutos a formato HH:MM
  String _convertirMinutosAHoras(double minutos) {
    int horas = minutos ~/ 60;
    int minutosRestantes = (minutos % 60).toInt();
    return "$horas:${minutosRestantes.toString().padLeft(2, '0')} H";
  }
}