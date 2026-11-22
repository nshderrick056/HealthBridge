
export '../domain/entities/enums.dart';

// Operations queued for synchronization with the server.
enum OutboxOp {
  upsert,
  delete,
}
