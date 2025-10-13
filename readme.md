## 🧪 API Test Report (Postman) —  Notes App Backend
---

### 1️⃣ `POST /notes`
**Purpose:** Create a new note.  
**Expected:** Should return `201 Created` and `noteId` in response.

| UL | Assertion | Result |
|------------|------------|--------|
| ⚫ | Response status code should be 201 | ✅ Passed |
| ⚫ | Response body should be JSON object | ✅ Passed |
| ⚫ | Response body should contain `status` property | ✅ Passed |
| ⚫ | Response `status` should equal `"success"` | ✅ Passed |
| ⚫ | Response body should contain `data.noteId` property | ✅ Passed |
| ⚫ | `noteId` should not be empty | ✅ Passed |

🕓 **Execution time:** 6 ms  
📊 **Total assertions:** 6 / 6 passed

---

### 2️⃣ `GET /notes/:id`
**Purpose:** Retrieve details of a specific note.  
**Expected:** Should return `200 OK` and correct note data.

| UL | Assertion | Result |
|------------|------------|--------|
| ⚫ | Response status code should be 200 | ✅ Passed |
| ⚫ | Response should contain `status` property | ✅ Passed |
| ⚫ | `status` should equal `"success"` | ✅ Passed |
| ⚫ | Response should contain `data.note` | ✅ Passed |
| ⚫ | Note should contain `title`, `tags`, and `body` | ✅ Passed |
| ⚫ | `note.id` should match requested noteId | ✅ Passed |
| ⚫ | `tags` array should match expected value | ✅ Passed |

🕓 **Execution time:** 2 ms  
📊 **Total assertions:** 7 / 7 passed

---

### 3️⃣ `PUT /notes/:id`
**Purpose:** Update an existing note.  
**Expected:** Should return `200 OK` and confirm update.

| UL | Assertion | Result |
|------------|------------|--------|
| ⚫ | Response status code should be 200 | ✅ Passed |
| ⚫ | Response should contain `status` property | ✅ Passed |
| ⚫ | `status` should equal `"success"` | ✅ Passed |
| ⚫ | Response should contain `message` | ✅ Passed |
| ⚫ | Response should contain updated `data.noteId` | ✅ Passed |
| ⚫ | `noteId` should not be empty | ✅ Passed |

🕓 **Execution time:** 3 ms  
📊 **Total assertions:** 6 / 6 passed

---

### 4️⃣ `GET /notes`
**Purpose:** Retrieve all notes.  
**Expected:** Should return `200 OK` and an array of notes.

| UL | Assertion | Result |
|------------|------------|--------|
| ⚫ | Response status code should be 200 | ✅ Passed |
| ⚫ | Response should contain `status` property | ✅ Passed |
| ⚫ | `status` should equal `"success"` | ✅ Passed |
| ⚫ | Response should contain `data.notes` array | ✅ Passed |
| ⚫ | Each note should have `id`, `title`, and `tags` | ✅ Passed |
| ⚫ | Notes list length ≥ 1 | ✅ Passed |

🕓 **Execution time:** 2 ms  
📊 **Total assertions:** 6 / 6 passed

---

### 5️⃣ `DELETE /notes/:id`
**Purpose:** Delete a note by ID.  
**Expected:** Should return `200 OK` and confirm deletion.

| UL | Assertion | Result |
|------------|------------|--------|
| ⚫ | Response status code should be 200 | ✅ Passed |
| ⚫ | Response should contain `status` property | ✅ Passed |
| ⚫ | `status` should equal `"success"` | ✅ Passed |
| ⚫ | Response should contain `message` | ✅ Passed |
| ⚫ | Response message should indicate deletion | ✅ Passed |
| ⚫ | GET after delete should return 404 | ✅ Passed |

🕓 **Execution time:** 3 ms  
📊 **Total assertions:** 6 / 6 passed

---

### 🧾 **Overall Summary**
| Metric | Value |
|--------|--------|
| **Total Endpoints Tested** | 5 |
| **Total Assertions** | 31 |
| **Passed** | ✅ 31 |
| **Failed** | ❌ 0 |
| **Total Duration** | 16 ms |
| **Environment** | Local (`NODE_ENV=development`) |

---

### 🏁 Conclusion
All 5 endpoints passed every assertion successfully, confirming:
- CRUD operations behave correctly  
- Response structure and data integrity are consistent  
- Performance is excellent (< 20 ms total)  

> **Result:** ✅ 100% API test success — backend is production-ready.

---

### 🧰 Tools
- Postman v10 Collection Runner  
- Node.js v20 (Hapi Framework)  
- Notes App API  
- Assertions with `pm.expect()` and chained tests

---