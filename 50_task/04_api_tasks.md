# API 엔드포인트별 구현 태스크

본 문서는 SRS v3.0 Final의 System Context & Interfaces 섹션을 기반으로 각 API 엔드포인트별 구현 태스크를 분해한 것입니다.

---

## 인증 및 권한 관리 API

### API: POST /api/auth/login

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: POST /api/auth/login<br/>- Request Body: { email: string, password: string }<br/>- Response: { token: string, user: object }<br/>- 인증: None (공개 엔드포인트)<br/>- 에러 응답 코드 정의 (400, 401, 500) |
| **Request DTO** | - LoginRequestDto 클래스 정의<br/>- 필드: email (string, required, email format), password (string, required, min 8 chars)<br/>- Joi/Zod 스키마 정의<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - LoginResponseDto 클래스 정의<br/>- 필드: token (string), user (UserDto)<br/>- UserDto: { userId, email, name }<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - AuthController.login() 메서드 구현<br/>- Request DTO 바인딩<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 (try-catch) |
| **Service** | - AuthService.login() 메서드 구현<br/>- 이메일/비밀번호 검증<br/>- 사용자 정보 조회 (Firestore 또는 Firebase Auth)<br/>- 비밀번호 검증 (bcrypt 또는 Firebase Auth)<br/>- JWT 토큰 생성 (또는 Firebase Auth 토큰)<br/>- 인증 실패 시 에러 throw |
| **Validation** | - Request DTO 검증 (Joi/Zod)<br/>- 이메일 형식 검증<br/>- 비밀번호 길이 검증 (최소 8자)<br/>- 필수 필드 검증<br/>- 검증 실패 시 400 Bad Request 반환 |
| **Error Code** | - AUTH_001: 이메일이 존재하지 않음 (401)<br/>- AUTH_002: 비밀번호가 일치하지 않음 (401)<br/>- AUTH_003: 인증 서비스 장애 (500)<br/>- VALIDATION_001: 요청 데이터 검증 실패 (400) |
| **Logging/Monitoring** | - 로그인 시도 로깅 (info 레벨)<br/>- 로그인 성공/실패 로깅<br/>- 인증 실패 횟수 모니터링<br/>- 응답 시간 모니터링 (목표: 500ms 이내) |
| **E2E 테스트** | - 정상 로그인 시나리오 테스트<br/>- 잘못된 이메일 입력 테스트<br/>- 잘못된 비밀번호 입력 테스트<br/>- 요청 데이터 검증 실패 테스트<br/>- 응답 시간 테스트 (500ms 이내) |

### API: POST /api/auth/logout

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: POST /api/auth/logout<br/>- Request Body: 없음<br/>- Response: { message: string }<br/>- 인증: Required (JWT 토큰)<br/>- 에러 응답 코드 정의 (401, 500) |
| **Request DTO** | - 없음 (인증 토큰만 사용) |
| **Response DTO** | - LogoutResponseDto 클래스 정의<br/>- 필드: message (string)<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - AuthController.logout() 메서드 구현<br/>- JWT 토큰 검증 미들웨어 적용<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 |
| **Service** | - AuthService.logout() 메서드 구현<br/>- 토큰 무효화 처리 (선택적, 토큰 블랙리스트 관리)<br/>- 로그아웃 이력 저장 (선택적) |
| **Validation** | - JWT 토큰 검증 (미들웨어)<br/>- 토큰 만료/무효 검증<br/>- 검증 실패 시 401 Unauthorized 반환 |
| **Error Code** | - AUTH_004: 토큰이 없음 (401)<br/>- AUTH_005: 토큰이 만료됨 (401)<br/>- AUTH_006: 토큰이 무효함 (401) |
| **Logging/Monitoring** | - 로그아웃 시도 로깅 (info 레벨)<br/>- 로그아웃 성공 로깅<br/>- 응답 시간 모니터링 |
| **E2E 테스트** | - 정상 로그아웃 시나리오 테스트<br/>- 토큰 없이 요청 테스트 (401)<br/>- 만료된 토큰으로 요청 테스트 (401)<br/>- 무효한 토큰으로 요청 테스트 (401) |

---

## 학생 관리 API

### API: GET /api/students

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: GET /api/students<br/>- Query Parameters: ?search={query}&page={page}&limit={limit}<br/>- Response: { students: array, total: number, page: number }<br/>- 인증: Required (JWT 토큰)<br/>- 에러 응답 코드 정의 (400, 401, 500) |
| **Request DTO** | - GetStudentsQueryDto 클래스 정의<br/>- 필드: search (string, optional), page (number, optional, default 1), limit (number, optional, default 20, max 50)<br/>- Joi/Zod 스키마 정의<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - GetStudentsResponseDto 클래스 정의<br/>- 필드: students (StudentDto[]), total (number), page (number)<br/>- StudentDto: { studentId, name, classId, branchId }<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - StudentsController.getStudents() 메서드 구현<br/>- Query 파라미터 바인딩<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 |
| **Service** | - StudentsService.getStudents() 메서드 구현<br/>- Firestore `students` 컬렉션에서 검색 쿼리로 필터링<br/>- 이름 또는 ID로 부분 일치 검색<br/>- 검색 결과 최대 50명 제한<br/>- 페이지네이션 적용<br/>- 전체 검색 결과 수 계산 |
| **Validation** | - Query 파라미터 검증 (Joi/Zod)<br/>- page, limit 숫자 형식 검증<br/>- limit 최대값 검증 (50)<br/>- 검증 실패 시 400 Bad Request 반환 |
| **Error Code** | - STUDENTS_001: Firestore 연결 실패 (500)<br/>- VALIDATION_002: Query 파라미터 검증 실패 (400)<br/>- AUTH_005: 토큰이 만료됨 (401) |
| **Logging/Monitoring** | - 학생 검색 요청 로깅 (info 레벨)<br/>- 검색 쿼리 로깅<br/>- 응답 시간 모니터링 (목표: 500ms 이내)<br/>- 검색 결과 수 모니터링 |
| **E2E 테스트** | - 정상 검색 시나리오 테스트<br/>- 부분 일치 검색 테스트<br/>- 페이지네이션 테스트<br/>- 빈 검색 결과 테스트<br/>- Query 파라미터 검증 실패 테스트<br/>- 응답 시간 테스트 (500ms 이내) |

### API: GET /api/students/{studentId}

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: GET /api/students/{studentId}<br/>- Path Parameters: studentId (string)<br/>- Response: { student: object }<br/>- 인증: Required (JWT 토큰)<br/>- 에러 응답 코드 정의 (400, 401, 404, 500) |
| **Request DTO** | - GetStudentParamsDto 클래스 정의<br/>- 필드: studentId (string, required, UUID format)<br/>- Joi/Zod 스키마 정의<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - GetStudentResponseDto 클래스 정의<br/>- 필드: student (StudentDetailDto)<br/>- StudentDetailDto: { studentId, name, classId, branchId, parentEmail, parentPhone, createdAt, updatedAt }<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - StudentsController.getStudent() 메서드 구현<br/>- Path 파라미터 바인딩<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 |
| **Service** | - StudentsService.getStudent() 메서드 구현<br/>- Firestore `students` 컬렉션에서 studentId로 조회<br/>- 학생 정보 반환<br/>- 학생이 존재하지 않으면 에러 throw |
| **Validation** | - Path 파라미터 검증 (Joi/Zod)<br/>- studentId 형식 검증<br/>- 검증 실패 시 400 Bad Request 반환 |
| **Error Code** | - STUDENTS_002: 학생이 존재하지 않음 (404)<br/>- STUDENTS_003: Firestore 연결 실패 (500)<br/>- VALIDATION_003: Path 파라미터 검증 실패 (400) |
| **Logging/Monitoring** | - 학생 상세 조회 요청 로깅 (info 레벨)<br/>- studentId 로깅<br/>- 응답 시간 모니터링 (목표: 500ms 이내) |
| **E2E 테스트** | - 정상 조회 시나리오 테스트<br/>- 존재하지 않는 studentId 테스트 (404)<br/>- 잘못된 studentId 형식 테스트 (400)<br/>- 응답 시간 테스트 (500ms 이내) |

---

## 리포트 생성 API

### API: POST /api/reports/generate

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: POST /api/reports/generate<br/>- Request Body: { studentId: string, format: "pdf" }<br/>- Response: { reportId: string, downloadUrl: string, status: "processing" \| "completed" }<br/>- 인증: Required (JWT 토큰)<br/>- 에러 응답 코드 정의 (400, 401, 404, 500) |
| **Request DTO** | - GenerateReportRequestDto 클래스 정의<br/>- 필드: studentId (string, required), format (string, required, enum: ["pdf"])<br/>- Joi/Zod 스키마 정의<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - GenerateReportResponseDto 클래스 정의<br/>- 필드: reportId (string), downloadUrl (string, optional), status (string, enum: ["processing", "completed"])<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - ReportsController.generateReport() 메서드 구현<br/>- Request DTO 바인딩<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 |
| **Service** | - ReportsService.generateReport() 메서드 구현<br/>- 리포트 생성 요청 수신<br/>- 리포트 생성 프로세스 시작 (비동기 또는 동기)<br/>- reportId 생성<br/>- 진행 상태 설정 (processing)<br/>- 리포트 생성 이력 저장<br/>- Vercel 함수 제한 고려 (비동기 처리 또는 큐 시스템) |
| **Validation** | - Request DTO 검증 (Joi/Zod)<br/>- studentId 형식 검증<br/>- format 값 검증 (pdf만 허용)<br/>- 학생 존재 여부 검증<br/>- 검증 실패 시 400 Bad Request 반환 |
| **Error Code** | - REPORTS_001: 학생이 존재하지 않음 (404)<br/>- REPORTS_002: 리포트 생성 실패 (500)<br/>- REPORTS_003: Vercel 함수 실행 시간 제한 초과 (500)<br/>- REPORTS_004: 중복 리포트 생성 요청 (400)<br/>- VALIDATION_004: Request Body 검증 실패 (400) |
| **Logging/Monitoring** | - 리포트 생성 요청 로깅 (info 레벨)<br/>- 리포트 생성 시작/완료/실패 로깅<br/>- 리포트 생성 시간 모니터링 (목표: 30초 이내)<br/>- 리포트 생성 성공률 모니터링 (목표: 90% 이상)<br/>- 응답 시간 모니터링 |
| **E2E 테스트** | - 정상 리포트 생성 시나리오 테스트<br/>- 존재하지 않는 studentId 테스트 (404)<br/>- 잘못된 format 값 테스트 (400)<br/>- 리포트 생성 시간 제한 테스트 (30초)<br/>- 중복 요청 처리 테스트<br/>- 비동기 처리 테스트 (필요 시) |

### API: GET /api/reports/{reportId}/download

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: GET /api/reports/{reportId}/download<br/>- Path Parameters: reportId (string)<br/>- Response: File (PDF)<br/>- 인증: Required (JWT 토큰)<br/>- 에러 응답 코드 정의 (401, 404, 500) |
| **Request DTO** | - DownloadReportParamsDto 클래스 정의<br/>- 필드: reportId (string, required, UUID format)<br/>- Joi/Zod 스키마 정의<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - 없음 (PDF 파일 바이너리 반환) |
| **Controller** | - ReportsController.downloadReport() 메서드 구현<br/>- Path 파라미터 바인딩<br/>- Service 호출<br/>- PDF 파일 스트림 반환<br/>- Content-Type: application/pdf 설정<br/>- Content-Disposition 헤더 설정<br/>- 에러 핸들링 |
| **Service** | - ReportsService.downloadReport() 메서드 구현<br/>- Firestore에서 리포트 정보 조회<br/>- Firebase Storage에서 PDF 파일 다운로드 URL 생성<br/>- PDF 파일 스트림 반환<br/>- 리포트가 존재하지 않으면 에러 throw |
| **Validation** | - Path 파라미터 검증 (Joi/Zod)<br/>- reportId 형식 검증<br/>- 검증 실패 시 400 Bad Request 반환 |
| **Error Code** | - REPORTS_005: 리포트가 존재하지 않음 (404)<br/>- REPORTS_006: Firebase Storage 파일이 없음 (404)<br/>- REPORTS_007: 파일 다운로드 실패 (500)<br/>- AUTH_005: 토큰이 만료됨 (401) |
| **Logging/Monitoring** | - 리포트 다운로드 요청 로깅 (info 레벨)<br/>- reportId 로깅<br/>- 다운로드 성공/실패 로깅<br/>- 응답 시간 모니터링 (목표: 500ms 이내) |
| **E2E 테스트** | - 정상 다운로드 시나리오 테스트<br/>- 존재하지 않는 reportId 테스트 (404)<br/>- Firebase Storage 파일 없음 테스트 (404)<br/>- PDF 파일 형식 검증 테스트<br/>- 응답 시간 테스트 (500ms 이내) |

### API: GET /api/reports/history

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: GET /api/reports/history<br/>- Query Parameters: ?studentId={id}&page={page}&limit={limit}<br/>- Response: { reports: array, total: number }<br/>- 인증: Required (JWT 토큰)<br/>- 에러 응답 코드 정의 (400, 401, 500) |
| **Request DTO** | - GetReportsHistoryQueryDto 클래스 정의<br/>- 필드: studentId (string, optional), page (number, optional, default 1), limit (number, optional, default 20)<br/>- Joi/Zod 스키마 정의<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - GetReportsHistoryResponseDto 클래스 정의<br/>- 필드: reports (ReportHistoryDto[]), total (number)<br/>- ReportHistoryDto: { reportId, studentId, reportType, format, generatedAt, downloadedAt, status }<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - ReportsController.getReportsHistory() 메서드 구현<br/>- Query 파라미터 바인딩<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 |
| **Service** | - ReportsService.getReportsHistory() 메서드 구현<br/>- Firestore `reports` 컬렉션에서 조회<br/>- studentId 필터링 (선택적)<br/>- 생성 시간 기준 내림차순 정렬<br/>- 페이지네이션 적용<br/>- 전체 결과 수 계산 |
| **Validation** | - Query 파라미터 검증 (Joi/Zod)<br/>- page, limit 숫자 형식 검증<br/>- studentId 형식 검증 (선택적)<br/>- 검증 실패 시 400 Bad Request 반환 |
| **Error Code** | - REPORTS_008: Firestore 연결 실패 (500)<br/>- VALIDATION_005: Query 파라미터 검증 실패 (400) |
| **Logging/Monitoring** | - 리포트 이력 조회 요청 로깅 (info 레벨)<br/>- studentId 필터 로깅<br/>- 응답 시간 모니터링 (목표: 500ms 이내) |
| **E2E 테스트** | - 정상 조회 시나리오 테스트<br/>- studentId 필터링 테스트<br/>- 페이지네이션 테스트<br/>- 빈 결과 테스트<br/>- Query 파라미터 검증 실패 테스트<br/>- 응답 시간 테스트 (500ms 이내) |

---

## 리포트 전송 API

### API: POST /api/reports/{reportId}/send-email

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: POST /api/reports/{reportId}/send-email<br/>- Path Parameters: reportId (string)<br/>- Request Body: { parentEmail: string }<br/>- Response: { deliveryId: string, status: string }<br/>- 인증: Required (JWT 토큰)<br/>- 에러 응답 코드 정의 (400, 401, 404, 500) |
| **Request DTO** | - SendReportEmailRequestDto 클래스 정의<br/>- 필드: parentEmail (string, required, email format)<br/>- SendReportEmailParamsDto 클래스 정의<br/>- 필드: reportId (string, required, UUID format)<br/>- Joi/Zod 스키마 정의<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - SendReportEmailResponseDto 클래스 정의<br/>- 필드: deliveryId (string), status (string, enum: ["success", "failed"])<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - ReportsController.sendReportEmail() 메서드 구현<br/>- Path 파라미터 및 Request Body 바인딩<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 |
| **Service** | - ReportsService.sendReportEmail() 메서드 구현<br/>- Firestore에서 리포트 정보 조회<br/>- Firebase Storage에서 리포트 PDF 다운로드<br/>- 이메일 서비스 API 호출 (Resend, SendGrid 등)<br/>- 리포트 PDF를 이메일 첨부<br/>- 이메일 전송 요청<br/>- 리포트 전송 이력 저장<br/>- 리포트가 존재하지 않으면 에러 throw |
| **Validation** | - Path 파라미터 및 Request Body 검증 (Joi/Zod)<br/>- reportId 형식 검증<br/>- parentEmail 이메일 형식 검증<br/>- 검증 실패 시 400 Bad Request 반환 |
| **Error Code** | - REPORTS_009: 리포트가 존재하지 않음 (404)<br/>- REPORTS_010: Firebase Storage 파일이 없음 (404)<br/>- REPORTS_011: 이메일 전송 실패 (500)<br/>- REPORTS_012: 이메일 서비스 API 장애 (500)<br/>- VALIDATION_006: Request Body 검증 실패 (400) |
| **Logging/Monitoring** | - 리포트 이메일 전송 요청 로깅 (info 레벨)<br/>- reportId, parentEmail 로깅<br/>- 이메일 전송 성공/실패 로깅<br/>- 이메일 전송 시간 모니터링 (목표: 5초 이내)<br/>- 이메일 전송 성공률 모니터링 |
| **E2E 테스트** | - 정상 이메일 전송 시나리오 테스트<br/>- 존재하지 않는 reportId 테스트 (404)<br/>- Firebase Storage 파일 없음 테스트 (404)<br/>- 잘못된 이메일 형식 테스트 (400)<br/>- 이메일 전송 실패 테스트<br/>- 이메일 첨부 파일 검증 테스트 |

### API: GET /api/reports/delivery/history

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: GET /api/reports/delivery/history<br/>- Query Parameters: ?studentId={id}&page={page}&limit={limit}<br/>- Response: { deliveries: array, total: number }<br/>- 인증: Required (JWT 토큰)<br/>- 에러 응답 코드 정의 (400, 401, 500) |
| **Request DTO** | - GetDeliveryHistoryQueryDto 클래스 정의<br/>- 필드: studentId (string, optional), page (number, optional, default 1), limit (number, optional, default 20)<br/>- Joi/Zod 스키마 정의<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - GetDeliveryHistoryResponseDto 클래스 정의<br/>- 필드: deliveries (DeliveryHistoryDto[]), total (number)<br/>- DeliveryHistoryDto: { deliveryId, reportId, studentId, parentEmail, sentAt, deliveryStatus }<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - ReportsController.getDeliveryHistory() 메서드 구현<br/>- Query 파라미터 바인딩<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 |
| **Service** | - ReportsService.getDeliveryHistory() 메서드 구현<br/>- Firestore `report_delivery` 컬렉션에서 조회<br/>- studentId 필터링 (선택적)<br/>- 전송 시간 기준 내림차순 정렬<br/>- 페이지네이션 적용<br/>- 전체 결과 수 계산 |
| **Validation** | - Query 파라미터 검증 (Joi/Zod)<br/>- page, limit 숫자 형식 검증<br/>- studentId 형식 검증 (선택적)<br/>- 검증 실패 시 400 Bad Request 반환 |
| **Error Code** | - REPORTS_013: Firestore 연결 실패 (500)<br/>- VALIDATION_007: Query 파라미터 검증 실패 (400) |
| **Logging/Monitoring** | - 리포트 전송 이력 조회 요청 로깅 (info 레벨)<br/>- studentId 필터 로깅<br/>- 응답 시간 모니터링 (목표: 500ms 이내) |
| **E2E 테스트** | - 정상 조회 시나리오 테스트<br/>- studentId 필터링 테스트<br/>- 페이지네이션 테스트<br/>- 빈 결과 테스트<br/>- Query 파라미터 검증 실패 테스트<br/>- 응답 시간 테스트 (500ms 이내) |

---

## 데이터 통합 API

### API: POST /api/integrations/upload

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: POST /api/integrations/upload<br/>- Request Body: FormData { file: File, systemType: string }<br/>- Response: { uploadId: string, status: string, errors: array }<br/>- 인증: Required (JWT 토큰)<br/>- Content-Type: multipart/form-data<br/>- 에러 응답 코드 정의 (400, 401, 413, 500) |
| **Request DTO** | - UploadFileRequestDto 클래스 정의<br/>- 필드: file (File, required, max 50MB), systemType (string, required, enum: ["attendance", "study_time", "mock_exam", "payment"])<br/>- Joi/Zod 스키마 정의 (multipart/form-data 처리)<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - UploadFileResponseDto 클래스 정의<br/>- 필드: uploadId (string), status (string, enum: ["success", "partial", "failed"]), errors (ValidationErrorDto[])<br/>- ValidationErrorDto: { row: number, field: string, message: string }<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - IntegrationsController.uploadFile() 메서드 구현<br/>- FormData 파싱 (multer 또는 express-fileupload)<br/>- Request DTO 바인딩<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 |
| **Service** | - IntegrationsService.uploadFile() 메서드 구현<br/>- 파일 형식 검증 (CSV, .xlsx, .xls)<br/>- 파일 크기 검증 (최대 50MB)<br/>- 파일 파싱 (papaparse, xlsx 라이브러리)<br/>- 데이터 추출<br/>- 데이터 검증 수행<br/>- 검증 오류 수집<br/>- uploadId 생성<br/>- Vercel 함수 제한 고려 (클라이언트 측 파싱 안내) |
| **Validation** | - 파일 형식 검증 (CSV, .xlsx, .xls)<br/>- 파일 크기 검증 (최대 50MB)<br/>- systemType 값 검증<br/>- 데이터 검증 (필수 필드, 데이터 타입, 날짜 범위, 값 범위)<br/>- 검증 실패 시 400 Bad Request 반환<br/>- 파일 크기 초과 시 413 Payload Too Large 반환 |
| **Error Code** | - INTEGRATIONS_001: 파일 형식이 지원되지 않음 (400)<br/>- INTEGRATIONS_002: 파일 크기가 50MB를 초과함 (413)<br/>- INTEGRATIONS_003: 파일 파싱 실패 (400)<br/>- INTEGRATIONS_004: 데이터 검증 실패 (400)<br/>- INTEGRATIONS_005: Vercel 함수 페이로드 제한 초과 (400)<br/>- VALIDATION_008: Request Body 검증 실패 (400) |
| **Logging/Monitoring** | - 파일 업로드 요청 로깅 (info 레벨)<br/>- 파일 크기, systemType 로깅<br/>- 파일 파싱 성공/실패 로깅<br/>- 데이터 검증 오류 수 로깅<br/>- 파일 업로드 처리 시간 모니터링 (목표: 10초 이내, 50MB 파일 기준)<br/>- 업로드 성공률 모니터링 |
| **E2E 테스트** | - 정상 파일 업로드 시나리오 테스트 (CSV, Excel)<br/>- 지원되지 않는 파일 형식 테스트 (400)<br/>- 파일 크기 초과 테스트 (413)<br/>- 데이터 검증 실패 테스트<br/>- 파일 파싱 실패 테스트<br/>- 대용량 파일 처리 테스트 (50MB)<br/>- Vercel 함수 제한 테스트 |

### API: POST /api/integrations/manual

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: POST /api/integrations/manual<br/>- Request Body: { systemType: string, data: object }<br/>- Response: { status: string }<br/>- 인증: Required (JWT 토큰)<br/>- 에러 응답 코드 정의 (400, 401, 500) |
| **Request DTO** | - ManualDataInputRequestDto 클래스 정의<br/>- 필드: systemType (string, required, enum: ["attendance", "study_time", "mock_exam", "payment"]), data (object, required)<br/>- systemType별 data 스키마 정의 (동적 스키마)<br/>- Joi/Zod 스키마 정의<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - ManualDataInputResponseDto 클래스 정의<br/>- 필드: status (string, enum: ["success", "failed"])<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - IntegrationsController.manualInput() 메서드 구현<br/>- Request DTO 바인딩<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 |
| **Service** | - IntegrationsService.manualInput() 메서드 구현<br/>- 데이터 검증 수행<br/>- Firestore에 데이터 즉시 저장<br/>- 실시간 저장 완료 확인<br/>- 검증 실패 시 에러 throw |
| **Validation** | - Request Body 검증 (Joi/Zod)<br/>- systemType 값 검증<br/>- systemType별 data 스키마 검증<br/>- 필수 필드 검증<br/>- 데이터 타입 검증<br/>- 날짜 범위 검증<br/>- 값 범위 검증<br/>- 검증 실패 시 400 Bad Request 반환 |
| **Error Code** | - INTEGRATIONS_006: 데이터 검증 실패 (400)<br/>- INTEGRATIONS_007: Firestore 저장 실패 (500)<br/>- INTEGRATIONS_008: 필수 필드 누락 (400)<br/>- VALIDATION_009: Request Body 검증 실패 (400) |
| **Logging/Monitoring** | - 수동 데이터 입력 요청 로깅 (info 레벨)<br/>- systemType 로깅<br/>- 데이터 검증 성공/실패 로깅<br/>- 저장 성공/실패 로깅<br/>- 응답 시간 모니터링 (목표: 500ms 이내) |
| **E2E 테스트** | - 정상 수동 데이터 입력 시나리오 테스트<br/>- 데이터 검증 실패 테스트 (400)<br/>- 필수 필드 누락 테스트 (400)<br/>- 잘못된 systemType 테스트 (400)<br/>- Firestore 저장 실패 테스트<br/>- 응답 시간 테스트 (500ms 이내) |

### API: GET /api/integrations/dashboard

| Task | 설명 |
| --- | --- |
| **API 명세서** | - OpenAPI/Swagger 명세서 작성<br/>- 엔드포인트: GET /api/integrations/dashboard<br/>- Query Parameters: ?period={daily\|weekly\|monthly}<br/>- Response: { attendance: object, studyTime: object, mockExam: object, payment: object }<br/>- 인증: Required (JWT 토큰)<br/>- 에러 응답 코드 정의 (400, 401, 500) |
| **Request DTO** | - GetDashboardQueryDto 클래스 정의<br/>- 필드: period (string, optional, enum: ["daily", "weekly", "monthly"], default "weekly")<br/>- Joi/Zod 스키마 정의<br/>- TypeScript 인터페이스 정의 |
| **Response DTO** | - GetDashboardResponseDto 클래스 정의<br/>- 필드: attendance (AttendanceDashboardDto), studyTime (StudyTimeDashboardDto), mockExam (MockExamDashboardDto), payment (PaymentDashboardDto)<br/>- 각 DashboardDto는 집계 데이터 포함<br/>- TypeScript 인터페이스 정의 |
| **Controller** | - IntegrationsController.getDashboard() 메서드 구현<br/>- Query 파라미터 바인딩<br/>- Service 호출<br/>- Response DTO 반환<br/>- 에러 핸들링 |
| **Service** | - IntegrationsService.getDashboard() 메서드 구현<br/>- Firestore에서 기간별 데이터 조회<br/>- 출석률 집계<br/>- 학습 시간 집계<br/>- 모의고사 성적 집계<br/>- 결제 현황 집계<br/>- 테이블 형태로 데이터 구성 |
| **Validation** | - Query 파라미터 검증 (Joi/Zod)<br/>- period 값 검증<br/>- 검증 실패 시 400 Bad Request 반환 |
| **Error Code** | - INTEGRATIONS_009: Firestore 쿼리 실패 (500)<br/>- INTEGRATIONS_010: 데이터 집계 실패 (500)<br/>- VALIDATION_010: Query 파라미터 검증 실패 (400) |
| **Logging/Monitoring** | - 통합 대시보드 조회 요청 로깅 (info 레벨)<br/>- period 필터 로깅<br/>- 응답 시간 모니터링 (목표: 500ms 이내)<br/>- 집계 데이터 정확성 모니터링 |
| **E2E 테스트** | - 정상 대시보드 조회 시나리오 테스트<br/>- 기간별 필터링 테스트 (daily, weekly, monthly)<br/>- 집계 데이터 정확성 테스트<br/>- 빈 데이터 테스트<br/>- Query 파라미터 검증 실패 테스트<br/>- 응답 시간 테스트 (500ms 이내) |

---

## 공통 구현 태스크

### 공통: 인증 미들웨어

| Task | 설명 |
| --- | --- |
| **미들웨어 구현** | - JWT 토큰 검증 미들웨어 구현<br/>- Firebase Auth 토큰 검증 미들웨어 구현 (선택적)<br/>- 토큰 추출 (Authorization 헤더)<br/>- 토큰 유효성 검증<br/>- 토큰 만료 확인<br/>- 사용자 정보 추출<br/>- 요청 객체에 사용자 정보 추가 |
| **에러 처리** | - 토큰 없음: 401 Unauthorized<br/>- 토큰 만료: 401 Unauthorized<br/>- 토큰 무효: 401 Unauthorized |
| **로깅** | - 인증 실패 로깅 (warn 레벨)<br/>- 토큰 검증 시간 모니터링 |

### 공통: 에러 핸들링

| Task | 설명 |
| --- | --- |
| **에러 핸들러** | - 전역 에러 핸들러 미들웨어 구현<br/>- 에러 타입별 처리<br/>- 사용자 친화적인 에러 메시지 생성 (REQ-NF-018)<br/>- 에러 코드 매핑<br/>- 적절한 HTTP 상태 코드 반환 |
| **에러 응답 형식** | - { errorCode: string, message: string, details?: object }<br/>- 일관된 에러 응답 형식 |
| **로깅** | - 모든 에러 로깅 (error 레벨)<br/>- 에러 스택 트레이스 로깅 (개발 환경) |

### 공통: 로깅 및 모니터링

| Task | 설명 |
| --- | --- |
| **로깅 설정** | - Vercel 로그 또는 Firebase 로깅 설정<br/>- 로그 레벨 설정 (info, error, warn)<br/>- 구조화된 로깅 (JSON 형식)<br/>- 요청 ID 추적 (correlation ID) |
| **모니터링** | - API 응답 시간 모니터링 (목표: 평균 500ms 이내, REQ-NF-005)<br/>- 에러율 모니터링<br/>- 요청량 모니터링<br/>- 리포트 생성 성공률 모니터링 (목표: 90% 이상, REQ-NF-008) |
| **알림** | - 에러율 임계값 초과 시 알림<br/>- 응답 시간 임계값 초과 시 알림 |

### 공통: API 문서화

| Task | 설명 |
| --- | --- |
| **OpenAPI/Swagger** | - 모든 API 엔드포인트 문서화<br/>- Request/Response 스키마 정의<br/>- 에러 응답 예시 포함<br/>- 인증 방법 설명<br/>- Swagger UI 설정 |
| **API 버전 관리** | - API 버전 관리 전략 수립<br/>- 버전별 엔드포인트 관리 (선택적) |

---

## 요약

- **인증 및 권한 관리 API**: 2개 엔드포인트
- **학생 관리 API**: 2개 엔드포인트
- **리포트 생성 API**: 3개 엔드포인트
- **리포트 전송 API**: 2개 엔드포인트
- **데이터 통합 API**: 3개 엔드포인트
- **공통 구현 태스크**: 인증 미들웨어, 에러 핸들링, 로깅/모니터링, API 문서화
- **총 API 엔드포인트**: 12개

각 API 엔드포인트는 API 명세서, Request/Response DTO, Controller, Service, Validation, Error Code, Logging/Monitoring, E2E 테스트 항목으로 체계적으로 분해되었습니다.

