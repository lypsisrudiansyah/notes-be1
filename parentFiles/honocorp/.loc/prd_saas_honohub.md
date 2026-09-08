# Product Requirements Document (PRD) - SaaS honocorp Backend

## 1. Latar Belakang & Pernyataan Masalah (Problem Statement)
Pengembang dengan pengalaman bertahun-tahun di kerangka kerja sinkron seperti Laravel sering kali menghadapi hambatan skalabilitas ketika berhadapan dengan I/O intensif, *real-time streaming*, atau konkurensi tinggi. Di sisi lain, transisi ke ekosistem Node.js sering kali mengorbankan struktur (*convention*) yang rapi dan terprediksi, menghasilkan "spaghetti code".

**Masalah yang Ingin Diselesaikan:**
*   Membangun sistem backend asinkron berkinerja tinggi tanpa mengorbankan arsitektur modular yang rapi (seperti Service-Repository pattern di Laravel).
*   Menangani tugas-tugas berat (*background jobs*), notifikasi real-time, dan manipulasi data bervolume tinggi tanpa memblokir *thread* utama.
*   Menciptakan *codebase* berbasis TypeScript dengan *type-safety* dari *database* hingga ke *response* API, mengurangi kemungkinan *runtime error*.

## 2. Pendekatan & Objektif
**Pendekatan:** Menggunakan **HonoJS** di atas *runtime* **Node.js** (menggunakan `@hono/node-server`) sebagai lapisan HTTP yang super cepat dan minimalis. Struktur proyek akan direkayasa menyerupai pola Laravel (Routes, Middlewares, Controllers/Handlers, Services, Queues) agar ilmu *transferable* dapat dimaksimalkan. Database menggunakan **MySQL** yang diorkestrasi oleh **Drizzle ORM**.

**Objektif:**
*   Menghasilkan 100% Type-Safe API.
*   Mengimplementasikan ekosistem *Queue* (BullMQ) untuk tugas berat.
*   Arsitektur siap skala (*production-ready*) dengan standarisasi respons, *error handling*, dan validasi skema (Zod).

## 3. Spesifikasi Teknis (Tech Stack)
*   **Runtime:** Node.js (v20+ LTS)
*   **Framework:** HonoJS (`@hono/node-server`)
*   **Database:** MySQL 8.0+
*   **ORM / Query Builder:** Drizzle ORM (`drizzle-orm/mysql-core`) & `mysql2` driver
*   **Cache & Queue Broker:** Redis
*   **Background Jobs:** BullMQ
*   **Validation:** Zod (`@hono/zod-validator`)
*   **Security:** JWT, Bcrypt, Hono CORS, Hono Secure Headers
*   **Testing:** Vitest

---

## 4. Daftar Fitur (Features Matrix)

### Fitur Sederhana (Core & CRUD)
*   **Autentikasi Standard:** Register, Login, Logout dengan JWT.
*   **Manajemen Profil:** Update data profil dan ganti kata sandi.
*   **CRUD Master Data:** Manajemen Kategori, Tag, dan Status Proyek.
*   **RESTful API Base:** Standardisasi respons sukses (data/meta) dan gagal (error code/message).

### Fitur Menengah (Business Logic & Interaksi)
*   **Role-Based Access Control (RBAC):** Middleware untuk membatasi akses endpoint berdasarkan *role* (Admin, Manager, Staff).
*   **Manajemen Proyek & Tugas:** Pembuatan proyek, penugasan anggota (*many-to-many*), dan pelacakan status.
*   **Sistem Komentar (Nested):** Komentar pada tugas/proyek dengan relasi *self-referencing*.
*   **File Upload & Storage:** Mengunggah avatar atau dokumen ke *cloud storage* (AWS S3) dengan validasi tipe mime dan batas ukuran.
*   **Pagingasi & Filtering Drizzle:** Pagingasi kursor/offset yang efisien untuk tabel besar, disisipkan parameter *query string* dinamis.

### Fitur Komprehensif / Kompleks (Advanced Architecture)
*   **Background Jobs (BullMQ):** Pemrosesan antrean untuk pengiriman email massal dan pembuatan dokumen PDF (Invoice) secara asinkron tanpa memblokir HTTP response.
*   **Webhooks Handler:** Menerima dan memvalidasi *signature* status pembayaran dari Payment Gateway (misal: Midtrans/Stripe).
*   **Real-time Notifications (SSE/WebSockets):** Mendorong notifikasi langsung ke klien jika ada tugas baru yang ditugaskan atau status pembayaran berhasil.
*   **Database Transactions & Concurrency:** Menangani alur penagihan yang kompleks yang melibatkan 4-5 tabel secara serentak (Orders, Invoices, Payments, User Limits) dengan jaminan *rollback* jika satu langkah gagal.
*   **Hono RPC Client:** Membangun *type-definition* otomatis untuk dikonsumsi oleh aplikasi Frontend tanpa perlu *generate* Swagger berulang kali.

---

## 5. Struktur Folder & File yang Efektif
Struktur ini mengadopsi arsitektur *N-Tier* atau *Service-Oriented*, memisahkan lalu lintas HTTP dari logika bisnis dan kueri database.

```text
honocorp-backend/
├── src/
│   ├── app.ts                 # Entry point aplikasi (konfigurasi global, error handler)
│   ├── server.ts              # Inisialisasi @hono/node-server dan port
│   ├── config/                # Konfigurasi env, konstanta, koneksi DB/Redis
│   │   ├── db.ts              # Setup koneksi mysql2 dan Drizzle
│   │   ├── redis.ts           # Setup koneksi ioredis
│   │   └── env.ts             # Validasi process.env dengan Zod
│   ├── db/                    # Layer Data
│   │   ├── schema/            # Definisi tabel Drizzle (mirip migration/model)
│   │   │   ├── users.ts
│   │   │   ├── projects.ts
│   │   │   └── index.ts
│   │   ├── migrations/        # Folder output Drizzle Kit (auto-generated SQL)
│   │   └── seeders/           # Skrip pengisian data dummy
│   ├── http/                  # Layer Presentasi (Routing & HTTP)
│   │   ├── middlewares/       # Auth, RBAC, Logger, Error Handler
│   │   ├── routes/            # Pengelompokan router Hono (mirip api.php)
│   │   │   ├── auth.route.ts
│   │   │   └── project.route.ts
│   │   └── controllers/       # (Opsional/Handlers) Menerima Context, panggil Service
│   │       ├── auth.controller.ts
│   │       └── project.controller.ts
│   ├── services/              # Layer Logika Bisnis (Inti Aplikasi)
│   │   ├── auth.service.ts    # Logika hash password, generate JWT
│   │   └── project.service.ts # Logika transaksi, alokasi tugas
│   ├── repositories/          # (Opsional) Layer ekstraksi kueri Drizzle kompleks
│   ├── queues/                # Background Jobs
│   │   ├── workers/           # Definisi worker BullMQ
│   │   └── jobs/              # Logika payload dan proses per job (SendEmailJob.ts)
│   └── utils/                 # Helpers (Format date, hash string, standard response)
├── tests/                     # Unit & Integration tests (Vitest)
├── package.json
├── drizzle.config.ts          # Konfigurasi Drizzle Kit
├── tsconfig.json
└── .env
```

---

## 6. Todo List 100 Langkah Pembangunan (Node.js & MySQL)

### Fase 1: Setup, Runtime, dan Routing Dasar
- [ ] 1. Inisialisasi proyek Node.js (`npm init -y`) dan instalasi TypeScript (`npm i -D typescript tsx`).
- [ ] 2. Instalasi framework dasar: `npm i hono @hono/node-server`.
- [ ] 3. Buat file `src/server.ts` dan jalankan *server* HTTP sederhana di port 3000.
- [ ] 4. Eksplorasi objek `Context` (`c`): Coba kembalikan respons JSON statis.
- [ ] 5. Susun struktur folder sesuai spesifikasi PRD di atas.
- [ ] 6. Buat file `src/http/routes/index.route.ts` untuk menampung endpoint dasar (Health Check).
- [ ] 7. Pisahkan *handler* (Controller) dari definisi *router* untuk rute profil pengguna.
- [ ] 8. Implementasi Hono Logger Middleware bawaan di `app.ts`.
- [ ] 9. Implementasi Hono CORS Middleware untuk integrasi frontend.
- [ ] 10. Buat `src/config/env.ts` untuk memvalidasi `process.env` menggunakan Zod.

### Fase 2: Database Layer (MySQL & Drizzle)
- [ ] 11. Instalasi dependensi: `npm i drizzle-orm mysql2` dan `npm i -D drizzle-kit`.
- [ ] 12. Setup koneksi MySQL di `src/config/db.ts` menggunakan *connection pool* `mysql2/promise`.
- [ ] 13. Buat konfigurasi `drizzle.config.ts` di *root directory*.
- [ ] 14. Definisikan skema tabel `users` (id, name, email, password, role) di `src/db/schema/users.ts`.
- [ ] 15. Jalankan `npx drizzle-kit generate` untuk membuat migrasi SQL.
- [ ] 16. Jalankan `npx drizzle-kit push` atau tulis skrip migrasi khusus untuk mengeksekusi SQL ke database.
- [ ] 17. Buat Service CRUD dasar: Insert user baru menggunakan `db.insert().values()`.
- [ ] 18. Buat Service pembacaan data: Ambil daftar user menggunakan `db.select().from()`.
- [ ] 19. Definisikan tabel `projects` dan relasi *One-to-Many* (User has many Projects).
- [ ] 20. Definisikan tabel pivot `project_members` untuk relasi *Many-to-Many*.
- [ ] 21. Praktikkan *Nested Query* Drizzle untuk mengambil Proyek beserta nama anggotanya.
- [ ] 22. Bungkus logika pembuatan proyek dan penugasan anggota di dalam `db.transaction()`.
- [ ] 23. Buat file seeder Node.js menggunakan *library* Faker untuk mengisi 100 data user dummy.

### Fase 3: Validasi & Penanganan Error
- [ ] 24. Instalasi Zod: `npm i zod @hono/zod-validator`.
- [ ] 25. Buat skema validasi Zod untuk payload registrasi (nama, email format, password min 8 karakter).
- [ ] 26. Pasang middleware `zValidator` pada rute `POST /register`.
- [ ] 27. Buat validasi custom Zod (refine) untuk mengecek apakah email sudah terdaftar di DB.
- [ ] 28. Buat Global Error Handler di `app.onError()` untuk memformat error menjadi JSON standar (code, message).
- [ ] 29. Implementasi pelemparan error HTTP kustom (misal: `throw new HTTPException(404, { message: 'User not found' })`).
- [ ] 30. Buat Global Not Found Handler di `app.notFound()`.
- [ ] 31. Integrasi Winston/Pino di `app.ts` untuk *logging* sistem format JSON ke file.
- [ ] 32. Buat fungsi utilitas (*helper*) untuk membungkus standarisasi respons API (success vs fail).
- [ ] 33. Buat fungsi utilitas paginasi yang menerjemahkan parameter `page` dan `limit` menjadi operasi `limit` dan `offset` MySQL.

### Fase 4: Autentikasi & Otorisasi
- [ ] 34. Instalasi library kriptografi: `npm i bcryptjs`.
- [ ] 35. Buat utilitas untuk melakukan hash dan compare password.
- [ ] 36. Terapkan logika hash password pada *service* registrasi sebelum `db.insert()`.
- [ ] 37. Buat endpoint Login yang memvalidasi kredensial email dan password.
- [ ] 38. Implementasi JWT Hono (menggunakan modul bawaan `hono/jwt`). Sign payload berisi `userId` dan `role`.
- [ ] 39. Buat Middleware `authMiddleware` untuk memverifikasi Bearer Token JWT.
- [ ] 40. Tambahkan data *user* yang berhasil diverifikasi ke dalam objek Context (`c.set('user', payload)`).
- [ ] 41. Amankan rute `/profile` dengan `authMiddleware`.
- [ ] 42. Buat Middleware RBAC (`roleMiddleware(['admin', 'manager'])`).
- [ ] 43. Amankan rute penghapusan proyek dengan RBAC (hanya admin).
- [ ] 44. Setup Redis (`ioredis`) untuk menyimpan *refresh token* (opsional untuk keamanan tinggi).
- [ ] 45. Instalasi dan konfigurasi middleware *Rate Limiter* berbasis Redis (mencegah spam login).
- [ ] 46. Konfigurasi `Secure Headers` Hono untuk proteksi XSS dan Clickjacking.

### Fase 5: Background Jobs & Caching (BullMQ + Redis)
- [ ] 47. Buat Service yang memanfaatkan Redis untuk melakukan *cache* terhadap "Daftar Kategori Proyek".
- [ ] 48. Terapkan strategi *Cache Invalidation* saat ada kategori baru yang ditambahkan (hapus *key* Redis).
- [ ] 49. Instalasi pustaka antrean: `npm i bullmq`.
- [ ] 50. Konfigurasi koneksi Queue BullMQ dengan Redis di `src/config/redis.ts`.
- [ ] 51. Definisikan Queue bernama `email-queue`.
- [ ] 52. Buat file `src/queues/workers/email.worker.ts` untuk memproses *job* secara asinkron.
- [ ] 53. Modifikasi proses *Register*: tambahkan *job* pengiriman "Welcome Email" ke `email-queue` alih-alih mengirim langsung.
- [ ] 54. Jalankan *worker* di terminal terpisah (`tsx src/queues/workers/email.worker.ts`) dan verifikasi penerimaan pekerjaan.
- [ ] 55. Tambahkan logika penanganan kegagalan (*retry logic/exponential backoff*) pada *worker*.
- [ ] 56. Buat antrean untuk tugas berat: `pdf-queue` (untuk generate laporan proyek bulanan).
- [ ] 57. Integrasi `bull-board` (antarmuka UI BullMQ) pada rute Hono tertentu (dilindungi akses Admin).
- [ ] 58. Praktikkan *Task Scheduling* (Cron) dengan Queue terulang (*Repeatable Jobs*) untuk mengirim rekap tugas mingguan setiap hari Senin.

### Fase 6: Penanganan File & Integrasi Eksternal
- [ ] 59. Buat endpoint untuk mengubah Avatar profil (*multipart/form-data*).
- [ ] 60. Ekstrak data file menggunakan `c.req.parseBody()` milik Hono.
- [ ] 61. Buat utilitas validasi ukuran file maksimal 2MB dan tipe khusus (JPG/PNG).
- [ ] 62. Tulis file gambar tersebut ke direktori lokal sementara (`/tmp` atau `/uploads`) menggunakan `fs/promises`.
- [ ] 63. Instalasi `aws-sdk/client-s3` untuk interaksi *cloud storage*.
- [ ] 64. Buat Service yang mengunggah file dari memori (buffer) langsung ke AWS S3 (atau R2/Minio).
- [ ] 65. Kembalikan URL publik S3 tersebut dan simpan ke database pengguna.
- [ ] 66. Integrasi `Nodemailer` atau *fetch API* (seperti Resend API) di dalam *worker* email.
- [ ] 67. Susun *template* email pendaftaran menggunakan fungsionalitas HTML standar atau template *engine* ringan.
- [ ] 68. Bangun *service* API *client* menggunakan `fetch` native Node.js v20 untuk berkomunikasi dengan API eksternal (misal: mengambil data cuaca/lokasi proyek).

### Fase 7: Arsitektur Kompleks (Webhooks & Real-time)
- [ ] 69. Bangun skema database untuk Penagihan (`invoices` dan `payments`).
- [ ] 70. Integrasi API Pembuatan Tagihan (Stripe / Midtrans) dan kembalikan URL pembayaran ke klien.
- [ ] 71. Buat rute *Webhook Controller* untuk menerima *callback* dari gerbang pembayaran (tanpa middleware Auth JWT).
- [ ] 72. Implementasi validasi *signature* kriptografi pada webhook untuk memastikan validitas pengirim (keamanan wajib).
- [ ] 73. Jika webhook valid, kirim event pembaruan status database ke dalam BullMQ agar diproses di belakang layar.
- [ ] 74. Buat rute berbasis **Server-Sent Events (SSE)** menggunakan `streamSSE` Hono.
- [ ] 75. Sambungkan *worker* pembayaran yang sukses dengan *trigger* Redis Pub/Sub.
- [ ] 76. Saat Redis Pub/Sub menerima notifikasi pembayaran berhasil, salurkan notifikasi ke klien via koneksi SSE aktif.
- [ ] 77. (Opsional) Jika chat/kolaborasi waktu nyata diperlukan, integrasikan library `ws` berdampingan dengan `@hono/node-server`.
- [ ] 78. Amankan koneksi WebSocket dengan membaca parameter *token* JWT saat proses *handshake*.
- [ ] 79. Buat fitur *streaming* pengunduhan file CSV besar hasil ekspor proyek, menggunakan `stream` MySQL ke HTTP *response* Hono (mencegah OOM - *Out of Memory*).

### Fase 8: Pengujian (Testing) & Kualitas Kode
- [ ] 80. Instalasi `vitest` dan konfigurasikan `vitest.config.ts`.
- [ ] 81. Tulis Unit Test untuk modul kalkulasi logika bisnis murni (misal: utilitas penghitung denda keterlambatan).
- [ ] 82. Buat skrip *setup* test untuk membuat *database testing* tersendiri dan mengeksekusi migrasi Drizzle.
- [ ] 83. Tulis Integration Test untuk rute `POST /register`: verifikasi kembalian JSON dan pastikan data masuk ke *database testing*.
- [ ] 84. Uji validasi Zod: kirim *request body* yang kosong dan pastikan API membalas HTTP 400.
- [ ] 85. *Mocking*: Tulis *test* yang memalsukan (mock) pemanggilan `fetch` ke layanan S3 agar *test* tidak mengunggah file sungguhan.
- [ ] 86. Buat pengujian untuk RBAC: masuk sebagai *staff*, coba hapus proyek, pastikan mendapat HTTP 403.
- [ ] 87. Konfigurasi `ESLint` dan `Prettier` untuk gaya penulisan kode TypeScript yang konsisten.
- [ ] 88. Setup Husky (Pre-commit hook) untuk mencegah tim melakukan *commit* jika *linting* atau *test* gagal.

### Fase 9: RPC & Dokumentasi
- [ ] 89. Pelajari dan ekspor tipe dari router utama (`export type AppType = typeof routes`).
- [ ] 90. Simulasikan pembuatan aplikasi frontend di folder terpisah dan instal `hono/client`.
- [ ] 91. Integrasikan Hono RPC `hc<AppType>('http://localhost:3000')` dan rasakan *autocomplete* pemanggilan API di sisi klien.
- [ ] 92. Eksplorasi pembuatan monorepo sederhana (misal menggunakan NPM Workspaces) untuk menampung backend Hono dan frontend React.
- [ ] 93. Instalasi pustaka pendamping `@hono/zod-openapi` dan `@hono/swagger-ui`.
- [ ] 94. Ubah sedikit definisi router untuk mendukung spesifikasi OpenAPI (berguna untuk klien eksternal/mobile developer).
- [ ] 95. Verifikasi tampilan antarmuka visual Swagger UI di rute `/docs`.

### Fase 10: Persiapan Produksi (CI/CD & Deployment)
- [ ] 96. Tulis `Dockerfile` berbasis *Node Alpine*. Susun multi-stage build untuk menginstal *dependencies*, melakukan build TS (`tsc`), dan hanya menyalin file `.js` terkompilasi ke *image* final.
- [ ] 97. Tulis konfigurasi *docker-compose.yml* lokal untuk membungkus Hono API, MySQL, Redis, dan BullMQ Worker secara instan.
- [ ] 98. Siapkan ekosistem PM2: buat file `ecosystem.config.js` untuk menjalankan `dist/server.js` dan skrip *worker* dalam mode kluster (memaksimalkan multi-core CPU).
- [ ] 99. Buat pipeline GitHub Actions dasar: periksa integrasi (*Lint* & *Test*) setiap kali ada *Pull Request* baru.
- [ ] 100. Buat tahapan CD (Continuous Deployment) sederhana: eksekusi `drizzle-kit push` (migrasi produksi) dan lakukan *restart* PM2 secara otomatis pada server.