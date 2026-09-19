class DatabaseSchema {
  static const String createUsersTable = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      full_name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      phone TEXT,
      password TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'borrower',
      profile_image_path TEXT,
      created_at TEXT NOT NULL
    )
  ''';

  static const String createCategoriesTable = '''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      description TEXT
    )
  ''';

  static const String createAuthorsTable = '''
    CREATE TABLE authors (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      nationality TEXT,
      birth_date TEXT,
      biography TEXT
    )
  ''';

  static const String createPublishersTable = '''
    CREATE TABLE publishers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      address TEXT,
      phone TEXT,
      email TEXT
    )
  ''';

  // Modified to include pdf_path
  static const String createBooksTable = '''
    CREATE TABLE books (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      isbn TEXT,
      publish_year INTEGER,
      pages INTEGER,
      category_id INTEGER NOT NULL,
      author_id INTEGER NOT NULL,
      publisher_id INTEGER,
      description TEXT,
      pdf_path TEXT,
      cover_image_path TEXT,
      FOREIGN KEY (category_id) REFERENCES categories(id),
      FOREIGN KEY (author_id) REFERENCES authors(id),
      FOREIGN KEY (publisher_id) REFERENCES publishers(id)
    )
  ''';

  static const String createBookCopiesTable = '''
    CREATE TABLE book_copies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER NOT NULL,
      copy_number TEXT NOT NULL UNIQUE,
      shelf_number TEXT,
      status TEXT NOT NULL DEFAULT 'available',
      FOREIGN KEY (book_id) REFERENCES books(id)
    )
  ''';

  static const String createBorrowersTable = '''
    CREATE TABLE borrowers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      student_id TEXT UNIQUE,
      address TEXT,
      membership_date TEXT NOT NULL,
      membership_status TEXT NOT NULL DEFAULT 'active',
      balance REAL NOT NULL DEFAULT 0.0,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  ''';

  static const String createBorrowingsTable = '''
    CREATE TABLE borrowings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      borrower_id INTEGER NOT NULL,
      copy_id INTEGER NOT NULL,
      employee_user_id INTEGER NOT NULL,
      borrow_date TEXT NOT NULL,
      expected_return_date TEXT NOT NULL,
      actual_return_date TEXT,
      status TEXT NOT NULL DEFAULT 'borrowed',
      return_requested INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (borrower_id) REFERENCES borrowers(id) ON DELETE CASCADE,
      FOREIGN KEY (copy_id) REFERENCES book_copies(id) ON DELETE CASCADE,
      FOREIGN KEY (employee_user_id) REFERENCES users(id) ON DELETE RESTRICT
    )
  ''';

  static const String createFinesTable = '''
    CREATE TABLE fines (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      borrowing_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      reason TEXT NOT NULL,
      payment_status TEXT NOT NULL DEFAULT 'unpaid',
      created_at TEXT NOT NULL,
      FOREIGN KEY (borrowing_id) REFERENCES borrowings(id)
    )
  ''';

  static const String createReservationsTable = '''
    CREATE TABLE reservations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      borrower_id INTEGER NOT NULL,
      book_id INTEGER NOT NULL,
      reservation_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      FOREIGN KEY (borrower_id) REFERENCES borrowers(id),
      FOREIGN KEY (book_id) REFERENCES books(id)
    )
  ''';
}
