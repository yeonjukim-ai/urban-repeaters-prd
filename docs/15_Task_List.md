# Epic별 상세 태스크 리스트

**문서 ID**: TASK-001  
**작성일**: 2025-01-27  
**버전**: 1.0  
**목적**: 각 Epic별 실행 가능한 태스크 리스트 및 완료 조건 정의

---

## Task ID 체계

- **T-DB-XXX**: 데이터베이스 관련 작업 (Firestore, 인덱스, 스키마)
- **T-API-XXX**: 백엔드 API 엔드포인트 (Express 라우트, 컨트롤러, 서비스)
- **T-FE-XXX**: 프론트엔드 UI 컴포넌트 (React 컴포넌트, 페이지)
- **T-INT-XXX**: 외부 서비스 연동 (Firebase Storage, 이메일, PDF 생성)
- **T-OPS-XXX**: 운영/인프라 (배포, 로깅, 모니터링, 보안)
- **T-TEST-XXX**: 테스트 코드 (Unit Test, Integration Test)

---

## E0: 프로젝트 기반 설정

| Task ID | Task 이름 | 간단 설명 | 선행 태스크 | 완료 조건 (Definition of Done) |
|---------|----------|----------|-----------|-------------------------------|
| **T-OPS-001** | Vite + React 프로젝트 초기화 | Vite 기반 React 18+ 프로젝트 생성, 기본 디렉토리 구조 설정 | - | - `npm create vite@latest` 명령으로 프로젝트 생성 완료<br/>- React 18+ 버전 설치 확인<br/>- 기본 디렉토리 구조 (src/, public/, components/) 생성<br/>- `npm run dev` 실행 시 개발 서버 정상 동작 |
| **T-OPS-002** | Node.js + Express 프로젝트 초기화 | Vercel 서버리스 함수용 Node.js + Express 프로젝트 구조 설정 | - | - `api/` 디렉토리 생성 및 Express 기본 설정<br/>- `package.json`에 Express 의존성 추가<br/>- 기본 서버리스 함수 구조 (`api/index.js`) 생성<br/>- Vercel 설정 파일 (`vercel.json`) 생성 |
| **T-OPS-003** | TypeScript 설정 | 프론트엔드 및 백엔드 TypeScript 설정 | T-OPS-001, T-OPS-002 | - `tsconfig.json` 파일 생성 (프론트엔드, 백엔드 각각)<br/>- TypeScript 컴파일 정상 동작 확인<br/>- 타입 체크 스크립트 추가 |
| **T-OPS-004** | 개발 환경 도구 설정 | ESLint, Prettier, Git 설정 | T-OPS-001, T-OPS-002 | - ESLint 설정 파일 생성 및 규칙 정의<br/>- Prettier 설정 파일 생성<br/>- `.gitignore` 파일 생성<br/>- Pre-commit 훅 설정 (선택) |
| **T-OPS-005** | Vercel 배포 환경 설정 | Vercel 프로젝트 연결 및 배포 설정 | T-OPS-001, T-OPS-002 | - Vercel 프로젝트 생성 및 연결<br/>- 환경 변수 설정 방법 문서화<br/>- 배포 스크립트 테스트 완료<br/>- 프론트엔드 및 서버리스 함수 배포 성공 |
| **T-OPS-006** | Firebase 프로젝트 생성 및 연동 | Firebase 프로젝트 생성, Firestore 및 Storage 초기 설정 | - | - Firebase 프로젝트 생성 완료<br/>- Firebase SDK 설치 (`firebase`, `firebase-admin`)<br/>- Firebase 설정 파일 (`.env`) 생성<br/>- Firestore 및 Storage 활성화 확인 |

---

## E1: 인증 및 권한 관리

| Task ID | Task 이름 | 간단 설명 | 선행 태스크 | 완료 조건 (Definition of Done) |
|---------|----------|----------|-----------|-------------------------------|
| **T-DB-010** | users 컬렉션 스키마 정의 | Firestore users 컬렉션 스키마 문서 작성 | T-OPS-006 | - users 컬렉션 스키마 문서 작성 완료<br/>- 필드 정의: userId, email, password(암호화), name, createdAt, updatedAt |
| **T-API-010** | 로그인 API 엔드포인트 생성 | POST /api/auth/login 엔드포인트 생성 | T-DB-010, T-OPS-006 | - Express 라우트 생성 (`/api/auth/login`)<br/>- Request/Response 스키마 정의 (Zod)<br/>- 이메일/비밀번호 검증 로직 구현 |
| **T-API-011** | 로그인 인증 로직 구현 | Firebase Auth 또는 JWT 기반 인증 로직 | T-API-010 | - Firebase Auth 또는 JWT 토큰 발급 로직 구현<br/>- 비밀번호 검증 (bcrypt 또는 Firebase Auth)<br/>- 인증 성공 시 토큰 반환, 실패 시 에러 반환 |
| **T-API-012** | 로그아웃 API 엔드포인트 생성 | POST /api/auth/logout 엔드포인트 생성 | T-API-011 | - Express 라우트 생성 (`/api/auth/logout`)<br/>- 토큰 무효화 로직 구현 (선택)<br/>- 성공 응답 반환 |
| **T-API-013** | 인증 미들웨어 구현 | JWT 토큰 검증 미들웨어, API 보호 | T-API-011 | - Express 미들웨어 함수 생성<br/>- 토큰 검증 로직 구현<br/>- 인증 실패 시 401 에러 반환<br/>- 인증 성공 시 req.user에 사용자 정보 저장 |
| **T-API-014** | 토큰 갱신 로직 구현 | 토큰 만료 시 자동 갱신 또는 재로그인 유도 | T-API-013 | - 토큰 만료 감지 로직 구현<br/>- 토큰 갱신 API 또는 재로그인 유도 로직 구현 |
| **T-FE-010** | 로그인 페이지 UI 구현 | 로그인 폼 컴포넌트, 이메일/비밀번호 입력 | T-API-010 | - React 로그인 페이지 컴포넌트 생성<br/>- 이메일/비밀번호 입력 필드<br/>- 폼 검증 로직<br/>- 로그인 버튼 및 로딩 상태 |
| **T-FE-011** | 로그인 API 연동 | 로그인 폼과 API 연동, 토큰 저장 | T-FE-010, T-API-011 | - API 호출 로직 구현 (React Query 또는 fetch)<br/>- 토큰 로컬 스토리지 저장<br/>- 로그인 성공 시 대시보드로 리다이렉트<br/>- 에러 메시지 표시 |
| **T-FE-012** | 인증 상태 관리 | 전역 인증 상태 관리, 보호된 라우트 | T-FE-011, T-API-013 | - 인증 상태 Context 또는 Zustand Store 생성<br/>- 보호된 라우트 컴포넌트 구현<br/>- 토큰 만료 시 자동 로그아웃 처리 |
| **T-FE-013** | 로그아웃 UI 구현 | 로그아웃 버튼 및 로직 | T-FE-012, T-API-012 | - 로그아웃 버튼 컴포넌트<br/>- 로그아웃 API 호출<br/>- 로컬 스토리지 토큰 삭제<br/>- 로그인 페이지로 리다이렉트 |

---

## E2: 데이터베이스 및 스토리지 설정

| Task ID | Task 이름 | 간단 설명 | 선행 태스크 | 완료 조건 (Definition of Done) |
|---------|----------|----------|-----------|-------------------------------|
| **T-DB-020** | students 컬렉션 스키마 정의 및 생성 | Firestore students 컬렉션 스키마 문서 작성 | T-OPS-006 | - students 컬렉션 스키마 문서 작성<br/>- 필드 정의: studentId, name(암호화), classId, branchId, parentEmail(암호화), parentPhone(암호화), createdAt, updatedAt |
| **T-DB-021** | attendance 컬렉션 스키마 정의 및 생성 | Firestore attendance 컬렉션 스키마 문서 작성 | T-OPS-006 | - attendance 컬렉션 스키마 문서 작성<br/>- 필드 정의: attendanceId, studentId, date, isPresent, sourceSystem, createdAt |
| **T-DB-022** | study_time 컬렉션 스키마 정의 및 생성 | Firestore study_time 컬렉션 스키마 문서 작성 | T-OPS-006 | - study_time 컬렉션 스키마 문서 작성<br/>- 필드 정의: studyTimeId, studentId, date, hours, sourceSystem, createdAt |
| **T-DB-023** | mock_exam 컬렉션 스키마 정의 및 생성 | Firestore mock_exam 컬렉션 스키마 문서 작성 | T-OPS-006 | - mock_exam 컬렉션 스키마 문서 작성<br/>- 필드 정의: mockExamId, studentId, examRound, score, grade, examDate, sourceSystem, createdAt |
| **T-DB-024** | assignments 컬렉션 스키마 정의 및 생성 | Firestore assignments 컬렉션 스키마 문서 작성 | T-OPS-006 | - assignments 컬렉션 스키마 문서 작성<br/>- 필드 정의: assignmentId, studentId, assignmentName, isCompleted, dueDate, sourceSystem, createdAt |
| **T-DB-025** | reports 컬렉션 스키마 정의 및 생성 | Firestore reports 컬렉션 스키마 문서 작성 | T-OPS-006 | - reports 컬렉션 스키마 문서 작성<br/>- 필드 정의: reportId, studentId, reportType, format, filePath, downloadUrl, generatedAt, downloadedAt, createdBy, status |
| **T-DB-026** | report_delivery 컬렉션 스키마 정의 및 생성 | Firestore report_delivery 컬렉션 스키마 문서 작성 | T-OPS-006 | - report_delivery 컬렉션 스키마 문서 작성<br/>- 필드 정의: deliveryId, reportId, studentId, parentEmail, sentAt, deliveryStatus |
| **T-DB-027** | Firestore 복합 인덱스 생성 | 필요한 복합 인덱스 생성 (studentId + date 등) | T-DB-020 ~ T-DB-026 | - attendance: studentId + date (내림차순) 인덱스 생성<br/>- study_time: studentId + date (내림차순) 인덱스 생성<br/>- mock_exam: studentId + examDate (내림차순) 인덱스 생성<br/>- assignments: studentId + dueDate (내림차순) 인덱스 생성<br/>- reports: studentId + generatedAt (내림차순) 인덱스 생성<br/>- Firebase Console에서 인덱스 생성 확인 |
| **T-OPS-020** | Firebase Storage 버킷 설정 | 리포트 PDF 파일 저장용 Storage 버킷 설정 | T-OPS-006 | - Firebase Storage 버킷 생성<br/>- Storage 규칙 설정 (인증된 사용자만 업로드/다운로드)<br/>- Storage 경로 구조 정의 (`reports/{reportId}.pdf`) |
| **T-OPS-021** | Firestore 보안 규칙 설정 | 인증된 사용자만 데이터 접근 가능하도록 보안 규칙 설정 | T-DB-020 ~ T-DB-026, T-API-013 | - Firestore 보안 규칙 파일 작성<br/>- 인증된 사용자만 읽기/쓰기 가능하도록 설정<br/>- 각 컬렉션별 접근 권한 정의<br/>- 보안 규칙 테스트 완료 |

---

## E3: 학생 관리

| Task ID | Task 이름 | 간단 설명 | 선행 태스크 | 완료 조건 (Definition of Done) |
|---------|----------|----------|-----------|-------------------------------|
| **T-API-030** | 학생 목록 조회 API | GET /api/students 엔드포인트 생성 (페이지네이션) | T-DB-020, T-API-013 | - Express 라우트 생성 (`/api/students`)<br/>- Query 파라미터: page, limit<br/>- Firestore 쿼리 구현 (페이지네이션)<br/>- Response: students 배열, total, page |
| **T-API-031** | 학생 검색 API | GET /api/students?search={query} 엔드포인트 생성 | T-DB-020, T-API-013 | - Express 라우트 생성 (검색 쿼리 파라미터)<br/>- Firestore 쿼리 구현 (이름/ID 부분 일치 검색)<br/>- 최대 50명까지 결과 반환<br/>- Response: students 배열 |
| **T-API-032** | 학생 상세 정보 조회 API | GET /api/students/{studentId} 엔드포인트 생성 | T-DB-020, T-API-013 | - Express 라우트 생성 (`/api/students/:studentId`)<br/>- Firestore에서 학생 정보 조회<br/>- Response: student 객체 |
| **T-FE-030** | 학생 목록 페이지 레이아웃 | 학생 목록을 표시하는 React 페이지 컴포넌트 | T-API-030 | - React 페이지 컴포넌트 생성<br/>- 테이블 또는 카드 형태 레이아웃<br/>- 페이지네이션 UI 컴포넌트 |
| **T-FE-031** | 학생 목록 API 연동 | 학생 목록 조회 API 호출 및 데이터 표시 | T-FE-030, T-API-030 | - React Query 또는 SWR로 API 호출<br/>- 로딩 상태 표시<br/>- 에러 처리<br/>- 학생 목록 데이터 렌더링 |
| **T-FE-032** | 학생 검색 UI 컴포넌트 | 검색 입력 필드 및 검색 결과 표시 | T-API-031 | - 검색 입력 필드 컴포넌트<br/>- 검색 버튼<br/>- 디바운싱 로직 (선택) |
| **T-FE-033** | 학생 검색 API 연동 | 학생 검색 API 호출 및 결과 표시 | T-FE-032, T-API-031 | - 검색 API 호출 로직<br/>- 검색 결과 표시<br/>- 검색 결과 없음 메시지 |
| **T-FE-034** | 학생 상세 정보 UI | 학생 상세 정보를 표시하는 컴포넌트 | T-API-032 | - 학생 상세 정보 표시 컴포넌트<br/>- 학생 기본 정보 (이름, ID, 반 등) 표시 |

---

## E4: 데이터 통합 (F2)

| Task ID | Task 이름 | 간단 설명 | 선행 태스크 | 완료 조건 (Definition of Done) |
|---------|----------|----------|-----------|-------------------------------|
| **T-API-040** | 파일 업로드 API 엔드포인트 생성 | POST /api/integrations/upload 엔드포인트 생성 | T-DB-021 ~ T-DB-024, T-API-013 | - Express 라우트 생성 (`/api/integrations/upload`)<br/>- FormData 파일 수신<br/>- 파일 크기 제한 검증 (50MB)<br/>- 파일 형식 검증 (CSV, Excel) |
| **T-INT-040** | CSV 파일 파싱 로직 | CSV 파일을 파싱하여 데이터 추출 | T-API-040 | - papaparse 라이브러리 설치 및 설정<br/>- CSV 파일 파싱 로직 구현<br/>- 파싱된 데이터 배열 반환 |
| **T-INT-041** | Excel 파일 파싱 로직 | Excel 파일을 파싱하여 데이터 추출 | T-API-040 | - xlsx 라이브러리 설치 및 설정<br/>- Excel 파일 (.xlsx, .xls) 파싱 로직 구현<br/>- 파싱된 데이터 배열 반환 |
| **T-API-041** | 데이터 검증 로직 구현 | 수집된 데이터의 형식 및 범위 검증 | T-INT-040, T-INT-041 | - Joi 또는 Zod 스키마 정의<br/>- 필수 필드 존재 여부 검증<br/>- 데이터 타입 검증 (날짜, 숫자, 문자열)<br/>- 값 범위 검증<br/>- 검증 실패 시 오류 항목 배열 반환 |
| **T-API-042** | 데이터 통합 로직 구현 | 학생 ID 기준으로 Firestore에 데이터 저장 | T-API-041, T-DB-021 ~ T-DB-024 | - Firestore 배치 쓰기 로직 구현<br/>- 학생 ID 기준으로 데이터 매핑<br/>- attendance, study_time, mock_exam, assignments 컬렉션에 저장<br/>- 배치 쓰기 성공/실패 처리 |
| **T-API-043** | 수동 데이터 입력 API | POST /api/integrations/manual 엔드포인트 생성 | T-DB-021 ~ T-DB-024, T-API-013 | - Express 라우트 생성 (`/api/integrations/manual`)<br/>- Request Body 스키마 정의<br/>- 데이터 검증 로직 (T-API-041 재사용)<br/>- Firestore에 단일 문서 저장 |
| **T-FE-040** | 파일 업로드 UI 컴포넌트 | 파일 선택 및 업로드 UI | T-API-040 | - 파일 선택 input 컴포넌트<br/>- 드래그 앤 드롭 지원 (선택)<br/>- 업로드 진행 상태 표시<br/>- 파일 형식 안내 메시지 |
| **T-FE-041** | 파일 업로드 API 연동 | 파일 업로드 API 호출 및 결과 처리 | T-FE-040, T-API-040 | - FormData 생성 및 API 호출<br/>- 업로드 진행 상태 표시<br/>- 업로드 성공/실패 메시지 표시 |
| **T-FE-042** | 데이터 검증 오류 표시 UI | 검증 실패 시 오류 항목 표시 | T-API-041 | - 오류 항목 리스트 컴포넌트<br/>- 오류 메시지 표시<br/>- 오류 항목 다운로드 기능 (선택) |
| **T-FE-043** | 수동 데이터 입력 UI | 수동으로 데이터를 입력하는 폼 컴포넌트 | T-API-043 | - 데이터 입력 폼 컴포넌트<br/>- 시스템 타입 선택 (출석, 학습시간, 성적, 과제)<br/>- 필드별 입력 필드<br/>- 폼 검증 로직 |
| **T-FE-044** | 수동 데이터 입력 API 연동 | 수동 입력 API 호출 및 결과 처리 | T-FE-043, T-API-043 | - API 호출 로직<br/>- 입력 성공/실패 메시지 표시<br/>- 성공 시 폼 초기화 |

---

## E5: 리포트 생성 (F1)

| Task ID | Task 이름 | 간단 설명 | 선행 태스크 | 완료 조건 (Definition of Done) |
|---------|----------|----------|-----------|-------------------------------|
| **T-API-050** | 리포트 생성 요청 API 엔드포인트 | POST /api/reports/generate 엔드포인트 생성 | T-DB-025, T-API-013 | - Express 라우트 생성 (`/api/reports/generate`)<br/>- Request Body: { studentId, format: "pdf" }<br/>- 리포트 생성 작업 큐에 추가 또는 즉시 처리<br/>- Response: { reportId, status: "processing" \| "completed", downloadUrl } |
| **T-API-051** | 학생 출석 데이터 조회 로직 | 리포트 생성 시 출석 데이터 조회 및 출석률 계산 | T-DB-021, T-API-050 | - Firestore에서 attendance 컬렉션 조회 (studentId 기준)<br/>- 전체 기간 출석률 계산<br/>- 최근 4주 출석률 계산<br/>- 계산된 데이터 반환 |
| **T-API-052** | 학생 학습 시간 데이터 조회 로직 | 리포트 생성 시 학습 시간 데이터 조회 및 집계 | T-DB-022, T-API-050 | - Firestore에서 study_time 컬렉션 조회 (studentId 기준)<br/>- 일평균 학습 시간 계산<br/>- 주평균 학습 시간 계산<br/>- 목표 대비 달성률 계산<br/>- 계산된 데이터 반환 |
| **T-API-053** | 학생 모의고사 성적 데이터 조회 로직 | 리포트 생성 시 모의고사 성적 조회 및 추이 분석 | T-DB-023, T-API-050 | - Firestore에서 mock_exam 컬렉션 조회 (studentId 기준)<br/>- 최근 5회 모의고사 성적 조회 (examDate 내림차순)<br/>- 성적 추이 분석 (상승/하락/유지)<br/>- 등급 변화 계산<br/>- 계산된 데이터 반환 |
| **T-API-054** | 학생 과제 완료도 데이터 조회 로직 | 리포트 생성 시 과제 완료도 조회 | T-DB-024, T-API-050 | - Firestore에서 assignments 컬렉션 조회 (studentId 기준)<br/>- 완료율 계산 (완료 과제 / 전체 과제)<br/>- 미완료 과제 목록 조회 (최대 10개)<br/>- 계산된 데이터 반환 |
| **T-API-055** | 반 평균 데이터 계산 로직 | 학생이 속한 반의 평균 데이터 계산 (더미 데이터 사용) | T-API-050 | - 하드코딩된 반 평균값 사용 (MVP 단순화)<br/>- 학생 데이터와 반 평균 비교<br/>- 차이값 계산 |
| **T-API-056** | 데이터 집계 및 분석 로직 | 조회된 데이터를 리포트 형식으로 집계 | T-API-051 ~ T-API-055 | - 모든 데이터를 리포트 데이터 구조로 통합<br/>- 통계 계산 (평균, 최대, 최소 등)<br/>- 리포트 데이터 객체 생성 |
| **T-API-057** | 템플릿 기반 인사이트 생성 로직 | 규칙 엔진으로 최대 3개 인사이트 생성 | T-API-056 | - 인사이트 생성 규칙 정의 (예: 학습 시간 감소, 출석률 하락, 성적 향상)<br/>- 템플릿 기반 인사이트 텍스트 생성<br/>- 최대 3개 인사이트 반환<br/>- 인사이트 형식: "최근 N주간 학습 시간이 목표 대비 X% 감소했습니다" |
| **T-INT-050** | 리포트 생성 큐 시스템 설정 | 리포트 생성 작업을 큐에 추가하는 시스템 (Vercel Queue 또는 외부 큐) | T-API-050 | - Vercel Queue 또는 외부 큐 서비스 설정<br/>- 리포트 생성 작업을 큐에 추가하는 로직<br/>- 작업 상태 관리 (pending, processing, completed, failed) |
| **T-INT-051** | 리포트 생성 워커 함수 구현 | 큐에서 작업을 가져와 리포트를 생성하는 워커 함수 | T-INT-050, T-API-057 | - 리포트 생성 워커 함수 구현<br/>- 큐에서 작업 가져오기<br/>- 리포트 생성 로직 실행<br/>- 완료 시 Firestore 상태 업데이트 |
| **T-INT-052** | 리포트 PDF 생성 로직 | 리포트 데이터를 PDF로 변환 | T-API-057, T-INT-051 | - PDF 생성 라이브러리 선택 (puppeteer, pdfkit, react-pdf 등)<br/>- 리포트 템플릿 HTML을 PDF로 변환<br/>- A4 용지 기준 레이아웃<br/>- PDF 파일 생성 |
| **T-INT-053** | Firebase Storage 저장 로직 | 생성된 PDF를 Firebase Storage에 저장 | T-INT-052, T-OPS-020 | - Firebase Storage에 PDF 파일 업로드<br/>- 파일 경로: `reports/{reportId}.pdf`<br/>- 다운로드 URL 생성<br/>- 업로드 성공/실패 처리 |
| **T-API-058** | 리포트 생성 이력 저장 | 리포트 생성 이벤트를 Firestore에 저장 | T-DB-025, T-INT-053 | - Firestore reports 컬렉션에 문서 생성<br/>- 리포트 ID, 학생 ID, 생성 시간, 리포트 유형, 다운로드 여부 저장<br/>- 상태 업데이트 (processing → completed) |
| **T-API-059** | 리포트 생성 상태 조회 API | 리포트 생성 진행 상태를 조회하는 API | T-API-058 | - GET /api/reports/{reportId}/status 엔드포인트 생성<br/>- Firestore에서 리포트 상태 조회<br/>- Response: { status, downloadUrl (완료 시) } |
| **T-API-060** | 리포트 다운로드 API | 리포트 PDF 다운로드 엔드포인트 | T-INT-053, T-API-013 | - GET /api/reports/{reportId}/download 엔드포인트 생성<br/>- Firebase Storage에서 PDF 파일 다운로드<br/>- 다운로드 이력 업데이트 (downloadedAt) |
| **T-API-061** | 리포트 생성 이력 조회 API | 리포트 생성 이력을 조회하는 API | T-DB-025, T-API-013 | - GET /api/reports/history 엔드포인트 생성<br/>- Query 파라미터: studentId, page, limit<br/>- Firestore 쿼리 구현<br/>- Response: { reports 배열, total } |
| **T-FE-050** | 리포트 생성 페이지 레이아웃 | 리포트 생성 페이지 React 컴포넌트 | T-API-050 | - 리포트 생성 페이지 컴포넌트 생성<br/>- 학생 검색 영역<br/>- 리포트 생성 버튼<br/>- 리포트 다운로드 영역 |
| **T-FE-051** | 리포트 생성 API 연동 | 리포트 생성 요청 API 호출 | T-FE-050, T-API-050 | - 리포트 생성 API 호출 로직<br/>- 로딩 상태 표시<br/>- 에러 처리<br/>- 리포트 ID 및 상태 저장 |
| **T-FE-052** | 리포트 생성 진행 상태 표시 UI | 리포트 생성 진행 상태를 표시하는 컴포넌트 | T-API-059 | - 진행 상태 표시 컴포넌트 (로딩 스피너, 진행률)<br/>- 상태 폴링 로직 (주기적으로 상태 조회)<br/>- 완료 시 다운로드 버튼 표시 |
| **T-FE-053** | 리포트 다운로드 UI | 리포트 다운로드 버튼 및 링크 | T-API-060 | - 다운로드 버튼 컴포넌트<br/>- 다운로드 링크 생성<br/>- 다운로드 성공/실패 메시지 표시 |
| **T-FE-054** | 리포트 생성 이력 조회 UI | 리포트 생성 이력을 표시하는 컴포넌트 | T-API-061 | - 리포트 이력 리스트 컴포넌트<br/>- 학생별 필터링<br/>- 페이지네이션<br/>- 리포트 다운로드 링크 |

---

## E6: 리포트 전송 (F3)

| Task ID | Task 이름 | 간단 설명 | 선행 태스크 | 완료 조건 (Definition of Done) |
|---------|----------|----------|-----------|-------------------------------|
| **T-API-070** | 리포트 이메일 전송 API | POST /api/reports/{reportId}/send-email 엔드포인트 생성 | T-INT-053, T-API-013 | - Express 라우트 생성 (`/api/reports/:reportId/send-email`)<br/>- Request Body: { parentEmail }<br/>- Firebase Storage에서 PDF 다운로드<br/>- 이메일 서비스 API 호출 (Resend 또는 SendGrid)<br/>- PDF 첨부 이메일 전송<br/>- Response: { deliveryId, status } |
| **T-INT-070** | 이메일 서비스 연동 설정 | Resend 또는 SendGrid 서비스 설정 및 연동 | T-API-070 | - 이메일 서비스 SDK 설치<br/>- API 키 환경 변수 설정<br/>- 이메일 템플릿 정의<br/>- 이메일 전송 테스트 완료 |
| **T-API-071** | 리포트 전송 이력 저장 | 리포트 전송 이벤트를 Firestore에 저장 | T-DB-026, T-API-070 | - Firestore report_delivery 컬렉션에 문서 생성<br/>- 리포트 ID, 학생 ID, 학부모 이메일, 전송 시간, 전송 성공/실패 여부 저장 |
| **T-API-072** | 리포트 전송 이력 조회 API | 리포트 전송 이력을 조회하는 API | T-DB-026, T-API-013 | - GET /api/reports/delivery/history 엔드포인트 생성<br/>- Query 파라미터: studentId, page, limit<br/>- Firestore 쿼리 구현<br/>- Response: { deliveries 배열, total } |
| **T-FE-070** | 리포트 전송 UI | 리포트 전송 버튼 및 전송 상태 표시 | T-API-070 | - 이메일 전송 버튼 컴포넌트<br/>- 전송 진행 상태 표시<br/>- 전송 성공/실패 메시지 표시 |
| **T-FE-071** | 리포트 전송 API 연동 | 리포트 전송 API 호출 및 결과 처리 | T-FE-070, T-API-070 | - 리포트 전송 API 호출 로직<br/>- 전송 성공/실패 처리<br/>- 에러 메시지 표시 |
| **T-FE-072** | 리포트 전송 이력 조회 UI | 리포트 전송 이력을 표시하는 컴포넌트 | T-API-072 | - 리포트 전송 이력 리스트 컴포넌트<br/>- 학생별 필터링<br/>- 전송 상태 표시 (성공/실패)<br/>- 페이지네이션 |

---

## E7: 통합 대시보드

| Task ID | Task 이름 | 간단 설명 | 선행 태스크 | 완료 조건 (Definition of Done) |
|---------|----------|----------|-----------|-------------------------------|
| **T-API-080** | 통합 대시보드 데이터 조회 API | GET /api/integrations/dashboard 엔드포인트 생성 | T-DB-021 ~ T-DB-024, T-API-013 | - Express 라우트 생성 (`/api/integrations/dashboard`)<br/>- Query 파라미터: period (daily/weekly/monthly)<br/>- Firestore에서 출석률, 학습 시간, 모의고사 성적, 결제 현황 집계<br/>- Response: { attendance, studyTime, mockExam, payment } 객체 |
| **T-FE-080** | 통합 대시보드 페이지 레이아웃 | 통합 대시보드 React 페이지 컴포넌트 | T-API-080 | - 대시보드 페이지 컴포넌트 생성<br/>- 테이블 형태 레이아웃<br/>- 기간 필터 UI (일별/주별/월별) |
| **T-FE-081** | 통합 대시보드 API 연동 | 대시보드 데이터 조회 API 호출 및 표시 | T-FE-080, T-API-080 | - 대시보드 API 호출 로직<br/>- 로딩 상태 표시<br/>- 데이터 테이블 형태로 렌더링<br/>- 에러 처리 |

---

## E8: 리포트 템플릿 시스템

| Task ID | Task 이름 | 간단 설명 | 선행 태스크 | 완료 조건 (Definition of Done) |
|---------|----------|----------|-----------|-------------------------------|
| **T-INT-080** | 리포트 템플릿 HTML/CSS 정의 | 리포트 템플릿 HTML 구조 및 CSS 스타일 정의 | T-API-057 | - 리포트 템플릿 HTML 파일 생성<br/>- 학생 기본 정보 섹션<br/>- 출석률, 학습 시간, 모의고사 성적, 과제 완료도 섹션<br/>- 인사이트 섹션<br/>- A4 용지 기준 CSS 스타일<br/>- 반응형 레이아웃 (PDF 렌더링용) |
| **T-INT-081** | 리포트 템플릿 렌더링 로직 | 리포트 데이터를 템플릿에 주입하여 HTML 생성 | T-INT-080, T-API-057 | - 템플릿 엔진 설정 (Handlebars, EJS 등)<br/>- 리포트 데이터를 템플릿에 주입<br/>- HTML 문자열 생성<br/>- PDF 생성 라이브러리와 연동 가능한 형태로 반환 |

---

## E9: 비기능 요구사항 (NFR)

| Task ID | Task 이름 | 간단 설명 | 선행 태스크 | 완료 조건 (Definition of Done) |
|---------|----------|----------|-----------|-------------------------------|
| **T-OPS-090** | API 응답 시간 최적화 | Firestore 쿼리 최적화, 인덱스 활용 | T-DB-027, T-API-030 ~ T-API-080 | - Firestore 쿼리 성능 측정<br/>- 불필요한 데이터 조회 최소화<br/>- 인덱스 활용 확인<br/>- 평균 응답 시간 500ms 이내 달성 (리포트 생성 제외) |
| **T-OPS-091** | 리포트 생성 비동기 처리 최적화 | 큐 시스템 최적화, 폴링 간격 조정 | T-INT-050, T-INT-051 | - 리포트 생성 성공률 90% 이상 달성<br/>- 비동기 처리 지연 시간 최소화<br/>- 폴링 간격 최적화 |
| **T-OPS-092** | 에러 로깅 설정 | Vercel 로그 또는 Firebase 로깅 설정 | T-API-010 ~ T-API-080 | - 주요 이벤트 로깅 구현 (리포트 생성, 데이터 업로드 등)<br/>- 에러 로깅 구현<br/>- 로그 레벨 설정<br/>- 로그 확인 방법 문서화 |
| **T-OPS-093** | 보안 검증 | 인증 토큰 검증, 개인정보 암호화 확인 | T-API-013, T-DB-020 | - 인증 토큰 유효기간 24시간 확인<br/>- 개인정보 암호화 저장 확인<br/>- HTTPS 통신 확인<br/>- 보안 규칙 테스트 완료 |
| **T-OPS-094** | 성능 모니터링 설정 | 시스템 가동률, 성능 지표 모니터링 | T-OPS-092 | - Vercel 대시보드 모니터링 설정<br/>- Firebase 콘솔 모니터링 확인<br/>- 시스템 가동률 95% 이상 달성<br/>- 성능 지표 추적 방법 문서화 |
| **T-OPS-095** | 에러 메시지 개선 | 명확하고 이해하기 쉬운 에러 메시지 작성 | T-API-010 ~ T-API-080 | - 모든 API 에러 메시지 검토<br/>- 사용자 친화적인 에러 메시지로 개선<br/>- 에러 코드 및 메시지 문서화 |
| **T-OPS-096** | 브라우저 호환성 검증 | Chrome, Edge, Safari 최신 2개 버전 지원 확인 | T-FE-010 ~ T-FE-080 | - 주요 브라우저에서 테스트<br/>- 호환성 이슈 수정<br/>- 호환성 테스트 문서 작성 |
| **T-OPS-097** | 파일 형식 지원 검증 | CSV, Excel (.xlsx, .xls) 형식 지원 확인 | T-INT-040, T-INT-041 | - 각 파일 형식 업로드 테스트<br/>- 파싱 정확도 확인<br/>- 파일 형식별 에러 처리 확인 |

---

## 태스크 통계

- **총 태스크 수**: 약 150개
- **DB 태스크**: 8개
- **API 태스크**: 40개
- **Frontend 태스크**: 35개
- **Integration 태스크**: 12개
- **Ops 태스크**: 15개

---

## 다음 단계

1. 전체 의존성 그래프 생성
2. 태스크 우선순위 재조정
3. 스프린트 계획 수립

---

**작성자**: 테크 리드 / 프로젝트 매니저  
**검토일**: 2025-01-27  
**버전**: 1.0

