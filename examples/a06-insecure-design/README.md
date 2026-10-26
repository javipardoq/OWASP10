# A06:2025 — Diseño Inseguro (Insecure Design)

El diseño inseguro es la ausencia de controles **por diseño**: faltan requisitos de
seguridad y no se modelaron los casos de abuso. No se arregla con una librería ni con un
parche puntual; se previene con **threat modeling** y reglas de negocio explícitas.

## Qué hay acá
- **`THREAT-MODEL.md`** — threat model del endpoint de transferencia (STRIDE + casos de abuso).
- **`java/vulnerable`** y **`java/fixed`** — ejemplo ejecutable del caso de abuso AB1:
  una transferencia que no valida el monto permite un **monto negativo** que roba fondos
  al destinatario. El fix implementa las reglas R1–R4 del threat model.

## Cómo correrlo
```bash
cd java/vulnerable && ./run.sh     # http://127.0.0.1:8060
./attack.sh                        # alice "transfiere" -500 a bob y le roba 500
./verify.sh                        # pasa si el abuso funciona

cd ../fixed && ./verify.sh         # pasa si el monto negativo se rechaza y lo legítimo anda
```
Requisito: JDK 17+ (Maven Wrapper incluido).

## Por qué solo Java
El control de A06 es de **proceso y diseño**, no de sintaxis de un lenguaje. El mismo
razonamiento aplica a cualquier stack; el ejemplo en Java alcanza para la demo y el
`THREAT-MODEL.md` es language-agnostic. En la sesión, esta categoría se apoya sobre todo
en el threat model y en los casos de abuso.

## Referencias
- OWASP Top 10:2025 — A06 Insecure Design
- OWASP Threat Modeling Cheat Sheet · OWASP SAMM (diseño) · STRIDE
