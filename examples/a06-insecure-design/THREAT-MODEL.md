# Threat model — Transferencia de fondos (ejemplo A06)

El diseño inseguro no se arregla con una librería: se previene **modelando las amenazas
y los casos de abuso durante el diseño**, antes de escribir el código. Este es un threat
model mínimo del endpoint de transferencia, con el método STRIDE y casos de abuso.

## 1. Qué estamos protegiendo (activos)
- El saldo de las cuentas (integridad del dinero).
- La disponibilidad del servicio de transferencias.

## 2. Flujo
Cliente → `POST /transfer {from, to, amount}` → servicio → actualiza saldos.

## 3. Casos de abuso (lo que un atacante intentaría)
| # | Caso de abuso | Regla de seguridad que lo previene |
|---|---------------|------------------------------------|
| AB1 | Enviar un **monto negativo** para invertir la transferencia y robar al destinatario | R1: el monto debe ser > 0 |
| AB2 | Transferir **más que el saldo** (sobregiro / dinero inventado) | R2: monto ≤ saldo disponible |
| AB3 | Transferir **a sí mismo** o a una cuenta inexistente para provocar estados raros | R3: origen ≠ destino y ambos existen |
| AB4 | **Condiciones de carrera**: dos transferencias simultáneas que leen el mismo saldo | R4: la operación debe ser atómica |
| AB5 | **Repetición** (replay) de la misma petición | R5: idempotencia por id de operación |

## 4. STRIDE (resumen)
- **Tampering / Elevation:** AB1, AB2 — manipular monto para alterar saldos. → validación + atomicidad.
- **Repudiation:** falta de trazabilidad. → registrar cada transferencia (ver A09).
- **Denial of Service:** abuso de volumen. → rate limiting (ver A07).

## 5. Requisitos de seguridad derivados (entran al backlog como criterios de aceptación)
- R1 monto > 0 · R2 monto ≤ saldo · R3 cuentas válidas y distintas · R4 atómico · R5 idempotente.

## 6. Qué implementa el ejemplo
La carpeta `java/vulnerable` **no** modeló estas reglas (código "feliz": mueve fondos sin
validar). La carpeta `java/fixed` implementa R1, R2, R3 y R4 (sección `synchronized`). R5
(idempotencia) se deja como ejercicio y se menciona en el README.

> Lección: el bug de AB1 (monto negativo) no es un error de tipeo; es la ausencia de un
> **requisito de seguridad** que un threat model habría detectado en la fase de diseño.
