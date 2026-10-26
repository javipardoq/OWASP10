import 'package:test/test.dart';
import '../lib/account_repository.dart';

void main() {
  test("legitimo: alice lee su propia cuenta 1001", () {
    final repo = AccountRepository();
    final acc = repo.getAccount(callerId: "alice", accountId: 1001);
    expect(acc.owner, "alice");
    expect(acc.balance, 50000);
  });

  test("guard de UI: la pantalla de alice no muestra la cuenta de bob", () {
    final screen = AccountScreen("alice");
    expect(screen.canView(const Account(1002, "bob", 1200)), isFalse);
  });

  test("BLOQUEADO: cliente alterado salta el guard de UI pero la capa de datos deniega", () {
    final repo = AccountRepository();
    expect(() => repo.getAccount(callerId: "alice", accountId: 1002),
        throwsA(isA<ForbiddenException>()));
  });
}
