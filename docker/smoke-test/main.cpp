// Consumer smoke test for the packaged libpqxx tarball.
//
// Compiles the transaction_base::exec() overloads jerryv2 relies on
// (std::string query, with and without pqxx::params) and links the static
// archive plus libpq. No database is needed: query() is only compiled and
// linked, never called.
#include <cstdlib>
#include <iostream>
#include <string>

#include <pqxx/pqxx>

namespace
{
[[maybe_unused]] void query(pqxx::connection &conn)
{
  pqxx::work tx{conn};
  std::string const plain{"SELECT 1"};
  std::string const with_params{"SELECT $1::text, $2::int"};
  pqxx::result const r1{tx.exec(plain)};
  pqxx::result const r2{tx.exec(with_params, pqxx::params{std::string{"x"}, 2})};
  tx.commit();
  std::cout << r1.size() + r2.size() << '\n';
}
} // namespace

int main()
{
  // Exercise library code from the static archive without a server.
  std::string const s{pqxx::to_string(42)};
  if (s != "42" or pqxx::from_string<int>(s) != 42)
  {
    std::cerr << "string conversion round trip failed\n";
    return EXIT_FAILURE;
  }
  std::cout << "libpqxx " << PQXX_VERSION << " (ABI " << PQXX_ABI
            << ") smoke test OK\n";
  return EXIT_SUCCESS;
}
