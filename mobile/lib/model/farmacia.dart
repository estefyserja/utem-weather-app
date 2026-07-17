/// Representa una farmacia cercana obtenida desde la API.
///
/// Contiene la información principal de una farmacia cercana a las
/// coordenadas consultadas.
///
/// Se utiliza para transferir la información desde el servicio REST
/// hasta la interfaz de usuario.
class Farmacia {
  double latitud;
  double longitud;
  String cadena;
  int tienda;
  String nombre;
  String direccion;
  String telefono;
  String aperturaNormal;
  String cierreNormal;

  /// Constructor completo.
  Farmacia({
    required this.latitud,
    required this.longitud,
    required this.cadena,
    required this.tienda,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.aperturaNormal,
    required this.cierreNormal,
  });

  /// Crea una instancia de [Farmacia] a partir de un JSON.
  factory Farmacia.fromJson(Map<String, dynamic> json) => Farmacia(
    latitud: json["latitude"]?.toDouble(),
    longitud: json["longitude"]?.toDouble(),
    cadena: json["cadena"],
    tienda: json["tienda"],
    nombre: json["nombre"],
    direccion: json["direccion"],
    telefono: json["telefono"].toString(),
    aperturaNormal: json["apertura_normal"],
    cierreNormal: json["cierre_normal"],
  );

  /// Convierte la instancia a un mapa JSON.
  Map<String, dynamic> toJson() => {
    "latitude": latitud,
    "longitude": longitud,
    "cadena": cadena,
    "tienda": tienda,
    "nombre": nombre,
    "direccion": direccion,
    "telefono": telefono,
    "apertura_normal": aperturaNormal,
    "cierre_normal": cierreNormal,
  };
}