# Banco de sangre - Loja, Ecuador

Informe de fin de Unidad 1 - Base de datos (FEIRNNR, Carrera de Computación, Ciclo 3 A).

**Autor:** Darwin Javier Campoverde Navas
**Docente:** Edwin René Guamán Quinche

Diseño e implementación de una base de datos relacional para gestionar un banco de sangre:
donantes, donaciones, unidades, tamizaje, solicitudes de transfusión y trazabilidad.

## Contenido

| Archivo | Descripción |
| --- | --- |
| `sql/01_ddl.sql` | Crea la base `banco_sangre` y las 16 tablas con sus restricciones |
| `sql/02_dml.sql` | Datos de prueba completos (ficticios) |
| `sql/03_consultas.sql` | 5 consultas de álgebra relacional traducidas a SQL |
| `diagrama/Proyecto_BD` | Diagrama Entidad-Relación, editable en draw.io |

## Cómo ejecutarlo (MySQL 8.0.16 o superior)

```bash
mysql -u root -p < sql/01_ddl.sql
mysql -u root -p < sql/02_dml.sql
mysql -u root -p < sql/03_consultas.sql
```

Ejecutar siempre en ese orden: las claves foráneas fijan el orden de creación e inserción.
