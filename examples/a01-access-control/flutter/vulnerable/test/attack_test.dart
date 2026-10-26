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

  test("ATAQUE: cliente alterado salta el guard de UI y lee la cuenta de bob", () {
    final repo = AccountRepository();
    // El atacante no pasa por AccountScreen: llama a la capa de datos directamente.
    final acc = repo.getAccount(callerId: "alice", accountId: 1002);
    expect(acc.owner, "bob");
    expect(acc.balance, 1200);
  });
}
