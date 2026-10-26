// A01:2025 Broken Access Control (IDOR) - VERSION CORREGIDA (Dart / capa de datos Flutter)
//
// Riesgo movil real: la app Flutter oculta o bloquea pantallas ajenas (guard en la UI),
// pero el atacante controla el cliente (APK modificado, Frida, proxy) y llama al backend
// directamente. Por eso el servidor/capa de datos DEBE re-verificar la autorizacion.
// En una app real, AccountRepository seria el cliente `dio` hacia GET /accounts/{id}
// y la verificacion de propiedad viviria en el backend; aqui se modela en memoria.

class Account {
  final int id;
  final String owner;
  final int balance;
  const Account(this.id, this.owner, this.balance);
}

class NotFoundException implements Exception {
  final int accountId;
  NotFoundException(this.accountId);
}

class ForbiddenException implements Exception {
  final String callerId;
  final int accountId;
  ForbiddenException(this.callerId, this.accountId);
}

// Guard del lado del cliente (UI): mejora la UX pero NO es un control de seguridad.
class AccountScreen {
  final String currentUser;
  AccountScreen(this.currentUser);

  // Solo muestra el boton "ver cuenta" si la cuenta es del usuario (ids propios conocidos).
  bool canView(Account? acc) => acc != null && acc.owner == currentUser;
}

class AccountRepository {
  final Map<int, Account> _accounts = {
    1001: const Account(1001, 'alice', 50000),
    1002: const Account(1002, 'bob', 1200),
  };

  Account getAccount({required String callerId, required int accountId}) {
    final acc = _accounts[accountId];
    if (acc == null) throw NotFoundException(accountId);
    // FIX: la propiedad se verifica en la capa de datos/servicio (siempre, en el servidor
    // en una app real); el guard de la UI es solo comodidad, nunca el control de seguridad.
    if (acc.owner != callerId) throw ForbiddenException(callerId, accountId);
    return acc;
  }
}
