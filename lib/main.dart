import 'package:flutter/material.dart';
import 'taxes.dart'; // Importar la pantalla Taxes
import 'rutas.dart'; // Importar la pantalla Rutas

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COSTOS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: PantallaPrincipal(), // Asegúrate de que esto apunte a PantallaPrincipal
      debugShowCheckedModeBanner: false,
    );
  }
}

class PantallaPrincipal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('COSTOS'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Botón para abrir la pantalla "Rutas"
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PantallaRutas()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Cambiado de primary a backgroundColor
                foregroundColor: Colors.white, // Cambiado de onPrimary a foregroundColor
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: Text('Rutas'),
            ),
            SizedBox(height: 20),
            // Botón para abrir la pantalla "Taxes"
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantallaTaxes(rutas: []), // Pasa una lista vacía o una lista de rutas
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Cambiado de primary a backgroundColor
                foregroundColor: Colors.white, // Cambiado de onPrimary a foregroundColor
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: Text('Taxes'),
            ),
          ],
        ),
      ),
    );
  }
}