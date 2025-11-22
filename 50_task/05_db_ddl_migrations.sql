# DB DDL 및 Migration Scripts

본 문서는 SRS v3.0 Final의 Data Model을 기반으로 작성된 데이터베이스 스키마 정의입니다.

**데이터베이스**: PostgreSQL 14+ (또는 MySQL 8.0+)
**인코딩**: UTF-8

---

## 1. users 테이블

```sql
-- 사용자 테이블
CREATE TABLE users (
  user_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL, -- bcrypt 해시 또는 Firebase Auth 사용 시 NULL
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- 인덱스
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- 제약조건
-- email은 UNIQUE 제약조건으로 이미 정의됨
-- password는 NOT NULL 제약조건으로 이미 정의됨

-- ORM Entity 정의 (설명)
-- TypeScript/Node.js 예시:
-- class User {
--   @PrimaryColumn('varchar', { length: 36 })
--   userId: string;
--   
--   @Column('varchar', { length: 255, unique: true })
--   email: string;
--   
--   @Column('varchar', { length: 255, nullable: true })
--   password: string; // Firebase Auth 사용 시 nullable
--   
--   @Column('varchar', { length: 100 })
--   name: string;
--   
--   @CreateDateColumn()
--   createdAt: Date;
--   
--   @UpdateDateColumn()
--   updatedAt: Date;
-- }

-- 테스트 데이터
INSERT INTO users (user_id, email, password, name, created_at, updated_at) VALUES
('usr-001', 'admin@academy.com', '$2b$10$example_hash_here', '관리자', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('usr-002', 'manager@academy.com', '$2b$10$example_hash_here', '학사 관리자', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
```

---

## 2. students 테이블

```sql
-- 학생 테이블
CREATE TABLE students (
  student_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  name_encrypted TEXT NOT NULL, -- 암호화된 이름
  class_id VARCHAR(50) NOT NULL,
  branch_id VARCHAR(50) NOT NULL,
  parent_email_encrypted TEXT NOT NULL, -- 암호화된 학부모 이메일
  parent_phone_encrypted TEXT NOT NULL, -- 암호화된 학부모 전화번호
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스
CREATE INDEX idx_students_class_id ON students(class_id);
CREATE INDEX idx_students_branch_id ON students(branch_id);
CREATE INDEX idx_students_created_at ON students(created_at);
-- 검색을 위한 인덱스 (암호화된 필드는 인덱스 효과 제한적이지만 추가)
CREATE INDEX idx_students_name_search ON students USING gin(to_tsvector('korean', name_encrypted));

-- 제약조건
-- student_id는 PRIMARY KEY로 이미 정의됨
-- 모든 필드는 NOT NULL 제약조건으로 이미 정의됨

-- ORM Entity 정의 (설명)
-- class Student {
--   @PrimaryColumn('varchar', { length: 36 })
--   studentId: string;
--   
--   @Column('text')
--   nameEncrypted: string; // 암호화된 이름
--   
--   @Column('varchar', { length: 50 })
--   classId: string;
--   
--   @Column('varchar', { length: 50 })
--   branchId: string;
--   
--   @Column('text')
--   parentEmailEncrypted: string; // 암호화된 학부모 이메일
--   
--   @Column('text')
--   parentPhoneEncrypted: string; // 암호화된 학부모 전화번호
--   
--   @CreateDateColumn()
--   createdAt: Date;
--   
--   @UpdateDateColumn()
--   updatedAt: Date;
--   
--   @OneToMany(() => Attendance, attendance => attendance.student)
--   attendances: Attendance[];
--   
--   @OneToMany(() => StudyTime, studyTime => studyTime.student)
--   studyTimes: StudyTime[];
--   
--   @OneToMany(() => MockExam, mockExam => mockExam.student)
--   mockExams: MockExam[];
--   
--   @OneToMany(() => Assignment, assignment => assignment.student)
--   assignments: Assignment[];
--   
--   @OneToMany(() => Report, report => report.student)
--   reports: Report[];
-- }

-- 테스트 데이터
INSERT INTO students (student_id, name_encrypted, class_id, branch_id, parent_email_encrypted, parent_phone_encrypted, created_at, updated_at) VALUES
('std-001', 'encrypted_name_1', 'class-001', 'branch-001', 'encrypted_email_1', 'encrypted_phone_1', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('std-002', 'encrypted_name_2', 'class-001', 'branch-001', 'encrypted_email_2', 'encrypted_phone_2', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('std-003', 'encrypted_name_3', 'class-002', 'branch-001', 'encrypted_email_3', 'encrypted_phone_3', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
```

---

## 3. attendance 테이블

```sql
-- 출석 테이블
CREATE TABLE attendance (
  attendance_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  student_id VARCHAR(36) NOT NULL,
  date DATE NOT NULL,
  is_present BOOLEAN NOT NULL DEFAULT true,
  source_system VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_attendance_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT uq_attendance_student_date UNIQUE (student_id, date, source_system)
);

-- 인덱스
CREATE INDEX idx_attendance_student_id ON attendance(student_id);
CREATE INDEX idx_attendance_date ON attendance(date DESC);
CREATE INDEX idx_attendance_student_date ON attendance(student_id, date DESC); -- 복합 인덱스 (SRS 6.2.2)
CREATE INDEX idx_attendance_source_system ON attendance(source_system);
CREATE INDEX idx_attendance_created_at ON attendance(created_at);

-- 제약조건
-- student_id는 FK로 이미 정의됨
-- student_id, date, source_system 조합은 UNIQUE 제약조건으로 이미 정의됨
-- is_present는 DEFAULT true로 이미 정의됨

-- ORM Entity 정의 (설명)
-- class Attendance {
--   @PrimaryColumn('varchar', { length: 36 })
--   attendanceId: string;
--   
--   @Column('varchar', { length: 36 })
--   studentId: string;
//   
//   @ManyToOne(() => Student, student => student.attendances)
//   @JoinColumn({ name: 'student_id' })
//   student: Student;
//   
//   @Column('date')
//   date: Date;
//   
//   @Column('boolean', { default: true })
//   isPresent: boolean;
//   
//   @Column('varchar', { length: 50 })
//   sourceSystem: string;
//   
//   @CreateDateColumn()
//   createdAt: Date;
// }

-- 테스트 데이터
INSERT INTO attendance (attendance_id, student_id, date, is_present, source_system, created_at) VALUES
('att-001', 'std-001', '2025-01-01', true, 'attendance_app', CURRENT_TIMESTAMP),
('att-002', 'std-001', '2025-01-02', true, 'attendance_app', CURRENT_TIMESTAMP),
('att-003', 'std-001', '2025-01-03', false, 'attendance_app', CURRENT_TIMESTAMP),
('att-004', 'std-002', '2025-01-01', true, 'attendance_app', CURRENT_TIMESTAMP),
('att-005', 'std-002', '2025-01-02', true, 'attendance_app', CURRENT_TIMESTAMP);
```

---

## 4. study_time 테이블

```sql
-- 학습 시간 테이블
CREATE TABLE study_time (
  study_time_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  student_id VARCHAR(36) NOT NULL,
  date DATE NOT NULL,
  hours DECIMAL(5, 2) NOT NULL CHECK (hours >= 0 AND hours <= 24),
  source_system VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_study_time_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT uq_study_time_student_date UNIQUE (student_id, date, source_system)
);

-- 인덱스
CREATE INDEX idx_study_time_student_id ON study_time(student_id);
CREATE INDEX idx_study_time_date ON study_time(date DESC);
CREATE INDEX idx_study_time_student_date ON study_time(student_id, date DESC); -- 복합 인덱스 (SRS 6.2.2)
CREATE INDEX idx_study_time_source_system ON study_time(source_system);
CREATE INDEX idx_study_time_created_at ON study_time(created_at);

-- 제약조건
-- student_id는 FK로 이미 정의됨
-- student_id, date, source_system 조합은 UNIQUE 제약조건으로 이미 정의됨
-- hours는 CHECK 제약조건으로 0-24 범위로 이미 정의됨

-- ORM Entity 정의 (설명)
-- class StudyTime {
//   @PrimaryColumn('varchar', { length: 36 })
//   studyTimeId: string;
//   
//   @Column('varchar', { length: 36 })
//   studentId: string;
//   
//   @ManyToOne(() => Student, student => student.studyTimes)
//   @JoinColumn({ name: 'student_id' })
//   student: Student;
//   
//   @Column('date')
//   date: Date;
//   
//   @Column('decimal', { precision: 5, scale: 2 })
//   hours: number; // 0-24 범위
//   
//   @Column('varchar', { length: 50 })
//   sourceSystem: string;
//   
//   @CreateDateColumn()
//   createdAt: Date;
// }

-- 테스트 데이터
INSERT INTO study_time (study_time_id, student_id, date, hours, source_system, created_at) VALUES
('stt-001', 'std-001', '2025-01-01', 8.5, 'lms', CURRENT_TIMESTAMP),
('stt-002', 'std-001', '2025-01-02', 9.0, 'lms', CURRENT_TIMESTAMP),
('stt-003', 'std-001', '2025-01-03', 7.5, 'lms', CURRENT_TIMESTAMP),
('stt-004', 'std-002', '2025-01-01', 8.0, 'lms', CURRENT_TIMESTAMP),
('stt-005', 'std-002', '2025-01-02', 9.5, 'lms', CURRENT_TIMESTAMP);
```

---

## 5. mock_exam 테이블

```sql
-- 모의고사 성적 테이블
CREATE TABLE mock_exam (
  mock_exam_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  student_id VARCHAR(36) NOT NULL,
  exam_round INTEGER NOT NULL CHECK (exam_round > 0),
  score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
  grade VARCHAR(10) NOT NULL,
  exam_date DATE NOT NULL,
  source_system VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mock_exam_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT uq_mock_exam_student_round UNIQUE (student_id, exam_round, source_system)
);

-- 인덱스
CREATE INDEX idx_mock_exam_student_id ON mock_exam(student_id);
CREATE INDEX idx_mock_exam_exam_date ON mock_exam(exam_date DESC);
CREATE INDEX idx_mock_exam_student_exam_date ON mock_exam(student_id, exam_date DESC); -- 복합 인덱스 (SRS 6.2.2)
CREATE INDEX idx_mock_exam_source_system ON mock_exam(source_system);
CREATE INDEX idx_mock_exam_created_at ON mock_exam(created_at);
CREATE INDEX idx_mock_exam_grade ON mock_exam(grade);

-- 제약조건
-- student_id는 FK로 이미 정의됨
-- student_id, exam_round, source_system 조합은 UNIQUE 제약조건으로 이미 정의됨
-- exam_round는 CHECK 제약조건으로 양수로 이미 정의됨
-- score는 CHECK 제약조건으로 0-100 범위로 이미 정의됨

-- ORM Entity 정의 (설명)
-- class MockExam {
//   @PrimaryColumn('varchar', { length: 36 })
//   mockExamId: string;
//   
//   @Column('varchar', { length: 36 })
//   studentId: string;
//   
//   @ManyToOne(() => Student, student => student.mockExams)
//   @JoinColumn({ name: 'student_id' })
//   student: Student;
//   
//   @Column('integer')
//   examRound: number; // 양수
//   
//   @Column('integer')
//   score: number; // 0-100 범위
//   
//   @Column('varchar', { length: 10 })
//   grade: string; // 등급 (예: A, B, C, D, F)
//   
//   @Column('date')
//   examDate: Date;
//   
//   @Column('varchar', { length: 50 })
//   sourceSystem: string;
//   
//   @CreateDateColumn()
//   createdAt: Date;
// }

-- 테스트 데이터
INSERT INTO mock_exam (mock_exam_id, student_id, exam_round, score, grade, exam_date, source_system, created_at) VALUES
('mex-001', 'std-001', 1, 85, 'B', '2025-01-05', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-002', 'std-001', 2, 88, 'B', '2025-01-12', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-003', 'std-001', 3, 92, 'A', '2025-01-19', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-004', 'std-002', 1, 78, 'C', '2025-01-05', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-005', 'std-002', 2, 82, 'B', '2025-01-12', 'mock_exam_platform', CURRENT_TIMESTAMP);
```

---

## 6. assignments 테이블

```sql
-- 과제 테이블
CREATE TABLE assignments (
  assignment_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  student_id VARCHAR(36) NOT NULL,
  assignment_name VARCHAR(255) NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  due_date DATE NOT NULL,
  source_system VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_assignments_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE
);

-- 인덱스
CREATE INDEX idx_assignments_student_id ON assignments(student_id);
CREATE INDEX idx_assignments_due_date ON assignments(due_date DESC);
CREATE INDEX idx_assignments_student_due_date ON assignments(student_id, due_date DESC); -- 복합 인덱스 (SRS 6.2.2)
CREATE INDEX idx_assignments_is_completed ON assignments(is_completed);
CREATE INDEX idx_assignments_source_system ON assignments(source_system);
CREATE INDEX idx_assignments_created_at ON assignments(created_at);

-- 제약조건
-- student_id는 FK로 이미 정의됨
-- is_completed는 DEFAULT false로 이미 정의됨

-- ORM Entity 정의 (설명)
-- class Assignment {
//   @PrimaryColumn('varchar', { length: 36 })
//   assignmentId: string;
//   
//   @Column('varchar', { length: 36 })
//   studentId: string;
//   
//   @ManyToOne(() => Student, student => student.assignments)
//   @JoinColumn({ name: 'student_id' })
//   student: Student;
//   
//   @Column('varchar', { length: 255 })
//   assignmentName: string;
//   
//   @Column('boolean', { default: false })
//   isCompleted: boolean;
//   
//   @Column('date')
//   dueDate: Date;
//   
//   @Column('varchar', { length: 50 })
//   sourceSystem: string;
//   
//   @CreateDateColumn()
//   createdAt: Date;
// }

-- 테스트 데이터
INSERT INTO assignments (assignment_id, student_id, assignment_name, is_completed, due_date, source_system, created_at) VALUES
('asg-001', 'std-001', '수학 문제집 1장', true, '2025-01-10', 'lms', CURRENT_TIMESTAMP),
('asg-002', 'std-001', '영어 단어 암기', true, '2025-01-15', 'lms', CURRENT_TIMESTAMP),
('asg-003', 'std-001', '국어 독서록', false, '2025-01-20', 'lms', CURRENT_TIMESTAMP),
('asg-004', 'std-002', '수학 문제집 1장', true, '2025-01-10', 'lms', CURRENT_TIMESTAMP),
('asg-005', 'std-002', '영어 단어 암기', false, '2025-01-15', 'lms', CURRENT_TIMESTAMP);
```

---

## 7. reports 테이블

```sql
-- 리포트 테이블
CREATE TABLE reports (
  report_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  student_id VARCHAR(36) NOT NULL,
  report_type VARCHAR(50) NOT NULL,
  format VARCHAR(10) NOT NULL DEFAULT 'pdf' CHECK (format = 'pdf'),
  file_path TEXT NOT NULL, -- Firebase Storage 경로
  download_url TEXT,
  generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  downloaded_at TIMESTAMP,
  created_by VARCHAR(36) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
  CONSTRAINT fk_reports_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT fk_reports_created_by FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE RESTRICT
);

-- 인덱스
CREATE INDEX idx_reports_student_id ON reports(student_id);
CREATE INDEX idx_reports_generated_at ON reports(generated_at DESC);
CREATE INDEX idx_reports_student_generated_at ON reports(student_id, generated_at DESC); -- 복합 인덱스 (SRS 6.2.2)
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_created_by ON reports(created_by);
CREATE INDEX idx_reports_format ON reports(format);

-- 제약조건
-- student_id는 FK로 이미 정의됨
-- created_by는 FK로 이미 정의됨
-- format은 CHECK 제약조건으로 'pdf'만 허용으로 이미 정의됨
-- status는 CHECK 제약조건으로 'processing', 'completed', 'failed'만 허용으로 이미 정의됨

-- ORM Entity 정의 (설명)
-- class Report {
//   @PrimaryColumn('varchar', { length: 36 })
//   reportId: string;
//   
//   @Column('varchar', { length: 36 })
//   studentId: string;
//   
//   @ManyToOne(() => Student, student => student.reports)
//   @JoinColumn({ name: 'student_id' })
//   student: Student;
//   
//   @Column('varchar', { length: 50 })
//   reportType: string;
//   
//   @Column('varchar', { length: 10, default: 'pdf' })
//   format: string; // 'pdf'만 허용
//   
//   @Column('text')
//   filePath: string; // Firebase Storage 경로
//   
//   @Column('text', { nullable: true })
//   downloadUrl: string;
//   
//   @CreateDateColumn()
//   generatedAt: Date;
//   
//   @Column('timestamp', { nullable: true })
//   downloadedAt: Date;
//   
//   @Column('varchar', { length: 36 })
//   createdBy: string;
//   
//   @ManyToOne(() => User)
//   @JoinColumn({ name: 'created_by' })
//   creator: User;
//   
//   @Column('varchar', { length: 20, default: 'processing' })
//   status: 'processing' | 'completed' | 'failed';
//   
//   @OneToMany(() => ReportDelivery, delivery => delivery.report)
//   deliveries: ReportDelivery[];
// }

-- 테스트 데이터
INSERT INTO reports (report_id, student_id, report_type, format, file_path, download_url, generated_at, downloaded_at, created_by, status) VALUES
('rpt-001', 'std-001', 'comprehensive', 'pdf', 'reports/2025/01/rpt-001.pdf', 'https://storage.firebase.com/reports/rpt-001.pdf', CURRENT_TIMESTAMP, NULL, 'usr-001', 'completed'),
('rpt-002', 'std-002', 'comprehensive', 'pdf', 'reports/2025/01/rpt-002.pdf', 'https://storage.firebase.com/reports/rpt-002.pdf', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'usr-001', 'completed'),
('rpt-003', 'std-001', 'comprehensive', 'pdf', 'reports/2025/01/rpt-003.pdf', NULL, CURRENT_TIMESTAMP, NULL, 'usr-002', 'processing');
```

---

## 8. report_delivery 테이블

```sql
-- 리포트 전송 이력 테이블
CREATE TABLE report_delivery (
  delivery_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  report_id VARCHAR(36) NOT NULL,
  student_id VARCHAR(36) NOT NULL,
  parent_email VARCHAR(255) NOT NULL,
  sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  delivery_status VARCHAR(20) NOT NULL DEFAULT 'success' CHECK (delivery_status IN ('success', 'failed')),
  CONSTRAINT fk_report_delivery_report FOREIGN KEY (report_id) REFERENCES reports(report_id) ON DELETE CASCADE,
  CONSTRAINT fk_report_delivery_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT report_delivery_email_format CHECK (parent_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- 인덱스
CREATE INDEX idx_report_delivery_report_id ON report_delivery(report_id);
CREATE INDEX idx_report_delivery_student_id ON report_delivery(student_id);
CREATE INDEX idx_report_delivery_sent_at ON report_delivery(sent_at DESC);
CREATE INDEX idx_report_delivery_status ON report_delivery(delivery_status);
CREATE INDEX idx_report_delivery_parent_email ON report_delivery(parent_email);

-- 제약조건
-- report_id는 FK로 이미 정의됨
-- student_id는 FK로 이미 정의됨
-- delivery_status는 CHECK 제약조건으로 'success', 'failed'만 허용으로 이미 정의됨
-- parent_email은 CHECK 제약조건으로 이메일 형식으로 이미 정의됨

-- ORM Entity 정의 (설명)
-- class ReportDelivery {
//   @PrimaryColumn('varchar', { length: 36 })
//   deliveryId: string;
//   
//   @Column('varchar', { length: 36 })
//   reportId: string;
//   
//   @ManyToOne(() => Report, report => report.deliveries)
//   @JoinColumn({ name: 'report_id' })
//   report: Report;
//   
//   @Column('varchar', { length: 36 })
//   studentId: string;
//   
//   @ManyToOne(() => Student)
//   @JoinColumn({ name: 'student_id' })
//   student: Student;
//   
//   @Column('varchar', { length: 255 })
//   parentEmail: string;
//   
//   @CreateDateColumn()
//   sentAt: Date;
//   
//   @Column('varchar', { length: 20, default: 'success' })
//   deliveryStatus: 'success' | 'failed';
// }

-- 테스트 데이터
INSERT INTO report_delivery (delivery_id, report_id, student_id, parent_email, sent_at, delivery_status) VALUES
('del-001', 'rpt-001', 'std-001', 'parent1@example.com', CURRENT_TIMESTAMP, 'success'),
('del-002', 'rpt-002', 'std-002', 'parent2@example.com', CURRENT_TIMESTAMP, 'success'),
('del-003', 'rpt-001', 'std-001', 'parent1@example.com', CURRENT_TIMESTAMP, 'failed');
```

---

## 9. Migration Script (전체 실행)

```sql
-- ============================================
-- Migration Script: Initial Schema Creation
-- Version: 1.0.0
-- Date: 2025-01-27
-- Description: Create all tables, indexes, and constraints for Urban Repeaters MVP
-- ============================================

BEGIN;

-- 1. Create users table
CREATE TABLE users (
  user_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- 2. Create students table
CREATE TABLE students (
  student_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  name_encrypted TEXT NOT NULL,
  class_id VARCHAR(50) NOT NULL,
  branch_id VARCHAR(50) NOT NULL,
  parent_email_encrypted TEXT NOT NULL,
  parent_phone_encrypted TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create attendance table
CREATE TABLE attendance (
  attendance_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  student_id VARCHAR(36) NOT NULL,
  date DATE NOT NULL,
  is_present BOOLEAN NOT NULL DEFAULT true,
  source_system VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_attendance_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT uq_attendance_student_date UNIQUE (student_id, date, source_system)
);

-- 4. Create study_time table
CREATE TABLE study_time (
  study_time_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  student_id VARCHAR(36) NOT NULL,
  date DATE NOT NULL,
  hours DECIMAL(5, 2) NOT NULL CHECK (hours >= 0 AND hours <= 24),
  source_system VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_study_time_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT uq_study_time_student_date UNIQUE (student_id, date, source_system)
);

-- 5. Create mock_exam table
CREATE TABLE mock_exam (
  mock_exam_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  student_id VARCHAR(36) NOT NULL,
  exam_round INTEGER NOT NULL CHECK (exam_round > 0),
  score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
  grade VARCHAR(10) NOT NULL,
  exam_date DATE NOT NULL,
  source_system VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mock_exam_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT uq_mock_exam_student_round UNIQUE (student_id, exam_round, source_system)
);

-- 6. Create assignments table
CREATE TABLE assignments (
  assignment_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  student_id VARCHAR(36) NOT NULL,
  assignment_name VARCHAR(255) NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  due_date DATE NOT NULL,
  source_system VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_assignments_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE
);

-- 7. Create reports table
CREATE TABLE reports (
  report_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  student_id VARCHAR(36) NOT NULL,
  report_type VARCHAR(50) NOT NULL,
  format VARCHAR(10) NOT NULL DEFAULT 'pdf' CHECK (format = 'pdf'),
  file_path TEXT NOT NULL,
  download_url TEXT,
  generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  downloaded_at TIMESTAMP,
  created_by VARCHAR(36) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
  CONSTRAINT fk_reports_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT fk_reports_created_by FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE RESTRICT
);

-- 8. Create report_delivery table
CREATE TABLE report_delivery (
  delivery_id VARCHAR(36) PRIMARY KEY DEFAULT gen_random_uuid()::VARCHAR,
  report_id VARCHAR(36) NOT NULL,
  student_id VARCHAR(36) NOT NULL,
  parent_email VARCHAR(255) NOT NULL,
  sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  delivery_status VARCHAR(20) NOT NULL DEFAULT 'success' CHECK (delivery_status IN ('success', 'failed')),
  CONSTRAINT fk_report_delivery_report FOREIGN KEY (report_id) REFERENCES reports(report_id) ON DELETE CASCADE,
  CONSTRAINT fk_report_delivery_student FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT report_delivery_email_format CHECK (parent_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- ============================================
-- Create Indexes
-- ============================================

-- users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- students indexes
CREATE INDEX idx_students_class_id ON students(class_id);
CREATE INDEX idx_students_branch_id ON students(branch_id);
CREATE INDEX idx_students_created_at ON students(created_at);

-- attendance indexes
CREATE INDEX idx_attendance_student_id ON attendance(student_id);
CREATE INDEX idx_attendance_date ON attendance(date DESC);
CREATE INDEX idx_attendance_student_date ON attendance(student_id, date DESC);
CREATE INDEX idx_attendance_source_system ON attendance(source_system);
CREATE INDEX idx_attendance_created_at ON attendance(created_at);

-- study_time indexes
CREATE INDEX idx_study_time_student_id ON study_time(student_id);
CREATE INDEX idx_study_time_date ON study_time(date DESC);
CREATE INDEX idx_study_time_student_date ON study_time(student_id, date DESC);
CREATE INDEX idx_study_time_source_system ON study_time(source_system);
CREATE INDEX idx_study_time_created_at ON study_time(created_at);

-- mock_exam indexes
CREATE INDEX idx_mock_exam_student_id ON mock_exam(student_id);
CREATE INDEX idx_mock_exam_exam_date ON mock_exam(exam_date DESC);
CREATE INDEX idx_mock_exam_student_exam_date ON mock_exam(student_id, exam_date DESC);
CREATE INDEX idx_mock_exam_source_system ON mock_exam(source_system);
CREATE INDEX idx_mock_exam_created_at ON mock_exam(created_at);
CREATE INDEX idx_mock_exam_grade ON mock_exam(grade);

-- assignments indexes
CREATE INDEX idx_assignments_student_id ON assignments(student_id);
CREATE INDEX idx_assignments_due_date ON assignments(due_date DESC);
CREATE INDEX idx_assignments_student_due_date ON assignments(student_id, due_date DESC);
CREATE INDEX idx_assignments_is_completed ON assignments(is_completed);
CREATE INDEX idx_assignments_source_system ON assignments(source_system);
CREATE INDEX idx_assignments_created_at ON assignments(created_at);

-- reports indexes
CREATE INDEX idx_reports_student_id ON reports(student_id);
CREATE INDEX idx_reports_generated_at ON reports(generated_at DESC);
CREATE INDEX idx_reports_student_generated_at ON reports(student_id, generated_at DESC);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_created_by ON reports(created_by);
CREATE INDEX idx_reports_format ON reports(format);

-- report_delivery indexes
CREATE INDEX idx_report_delivery_report_id ON report_delivery(report_id);
CREATE INDEX idx_report_delivery_student_id ON report_delivery(student_id);
CREATE INDEX idx_report_delivery_sent_at ON report_delivery(sent_at DESC);
CREATE INDEX idx_report_delivery_status ON report_delivery(delivery_status);
CREATE INDEX idx_report_delivery_parent_email ON report_delivery(parent_email);

COMMIT;

-- ============================================
-- Rollback Script (if needed)
-- ============================================
-- DROP TABLE IF EXISTS report_delivery CASCADE;
-- DROP TABLE IF EXISTS reports CASCADE;
-- DROP TABLE IF EXISTS assignments CASCADE;
-- DROP TABLE IF EXISTS mock_exam CASCADE;
-- DROP TABLE IF EXISTS study_time CASCADE;
-- DROP TABLE IF EXISTS attendance CASCADE;
-- DROP TABLE IF EXISTS students CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;
```

---

## 10. 테스트 데이터 스크립트 (전체)

```sql
-- ============================================
-- Test Data Script
-- Description: Insert sample data for testing
-- ============================================

BEGIN;

-- Insert users
INSERT INTO users (user_id, email, password, name, created_at, updated_at) VALUES
('usr-001', 'admin@academy.com', '$2b$10$example_hash_here', '관리자', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('usr-002', 'manager@academy.com', '$2b$10$example_hash_here', '학사 관리자', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('usr-003', 'operator@academy.com', '$2b$10$example_hash_here', '운영 관리자', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Insert students
INSERT INTO students (student_id, name_encrypted, class_id, branch_id, parent_email_encrypted, parent_phone_encrypted, created_at, updated_at) VALUES
('std-001', 'encrypted_name_1', 'class-001', 'branch-001', 'encrypted_email_1', 'encrypted_phone_1', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('std-002', 'encrypted_name_2', 'class-001', 'branch-001', 'encrypted_email_2', 'encrypted_phone_2', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('std-003', 'encrypted_name_3', 'class-002', 'branch-001', 'encrypted_email_3', 'encrypted_phone_3', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('std-004', 'encrypted_name_4', 'class-002', 'branch-001', 'encrypted_email_4', 'encrypted_phone_4', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('std-005', 'encrypted_name_5', 'class-003', 'branch-001', 'encrypted_email_5', 'encrypted_phone_5', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Insert attendance (최근 4주 데이터)
INSERT INTO attendance (attendance_id, student_id, date, is_present, source_system, created_at) VALUES
-- std-001 출석 데이터
('att-001', 'std-001', CURRENT_DATE - INTERVAL '28 days', true, 'attendance_app', CURRENT_TIMESTAMP),
('att-002', 'std-001', CURRENT_DATE - INTERVAL '27 days', true, 'attendance_app', CURRENT_TIMESTAMP),
('att-003', 'std-001', CURRENT_DATE - INTERVAL '26 days', false, 'attendance_app', CURRENT_TIMESTAMP),
('att-004', 'std-001', CURRENT_DATE - INTERVAL '25 days', true, 'attendance_app', CURRENT_TIMESTAMP),
('att-005', 'std-001', CURRENT_DATE - INTERVAL '24 days', true, 'attendance_app', CURRENT_TIMESTAMP),
-- std-002 출석 데이터
('att-006', 'std-002', CURRENT_DATE - INTERVAL '28 days', true, 'attendance_app', CURRENT_TIMESTAMP),
('att-007', 'std-002', CURRENT_DATE - INTERVAL '27 days', true, 'attendance_app', CURRENT_TIMESTAMP),
('att-008', 'std-002', CURRENT_DATE - INTERVAL '26 days', true, 'attendance_app', CURRENT_TIMESTAMP),
('att-009', 'std-002', CURRENT_DATE - INTERVAL '25 days', true, 'attendance_app', CURRENT_TIMESTAMP),
('att-010', 'std-002', CURRENT_DATE - INTERVAL '24 days', true, 'attendance_app', CURRENT_TIMESTAMP);

-- Insert study_time (최근 4주 데이터)
INSERT INTO study_time (study_time_id, student_id, date, hours, source_system, created_at) VALUES
-- std-001 학습 시간 데이터
('stt-001', 'std-001', CURRENT_DATE - INTERVAL '28 days', 8.5, 'lms', CURRENT_TIMESTAMP),
('stt-002', 'std-001', CURRENT_DATE - INTERVAL '27 days', 9.0, 'lms', CURRENT_TIMESTAMP),
('stt-003', 'std-001', CURRENT_DATE - INTERVAL '26 days', 7.5, 'lms', CURRENT_TIMESTAMP),
('stt-004', 'std-001', CURRENT_DATE - INTERVAL '25 days', 8.0, 'lms', CURRENT_TIMESTAMP),
('stt-005', 'std-001', CURRENT_DATE - INTERVAL '24 days', 9.5, 'lms', CURRENT_TIMESTAMP),
-- std-002 학습 시간 데이터
('stt-006', 'std-002', CURRENT_DATE - INTERVAL '28 days', 8.0, 'lms', CURRENT_TIMESTAMP),
('stt-007', 'std-002', CURRENT_DATE - INTERVAL '27 days', 9.5, 'lms', CURRENT_TIMESTAMP),
('stt-008', 'std-002', CURRENT_DATE - INTERVAL '26 days', 8.5, 'lms', CURRENT_TIMESTAMP),
('stt-009', 'std-002', CURRENT_DATE - INTERVAL '25 days', 9.0, 'lms', CURRENT_TIMESTAMP),
('stt-010', 'std-002', CURRENT_DATE - INTERVAL '24 days', 10.0, 'lms', CURRENT_TIMESTAMP);

-- Insert mock_exam (최근 5회)
INSERT INTO mock_exam (mock_exam_id, student_id, exam_round, score, grade, exam_date, source_system, created_at) VALUES
-- std-001 모의고사 성적
('mex-001', 'std-001', 1, 85, 'B', CURRENT_DATE - INTERVAL '35 days', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-002', 'std-001', 2, 88, 'B', CURRENT_DATE - INTERVAL '28 days', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-003', 'std-001', 3, 92, 'A', CURRENT_DATE - INTERVAL '21 days', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-004', 'std-001', 4, 90, 'A', CURRENT_DATE - INTERVAL '14 days', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-005', 'std-001', 5, 94, 'A', CURRENT_DATE - INTERVAL '7 days', 'mock_exam_platform', CURRENT_TIMESTAMP),
-- std-002 모의고사 성적
('mex-006', 'std-002', 1, 78, 'C', CURRENT_DATE - INTERVAL '35 days', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-007', 'std-002', 2, 82, 'B', CURRENT_DATE - INTERVAL '28 days', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-008', 'std-002', 3, 85, 'B', CURRENT_DATE - INTERVAL '21 days', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-009', 'std-002', 4, 88, 'B', CURRENT_DATE - INTERVAL '14 days', 'mock_exam_platform', CURRENT_TIMESTAMP),
('mex-010', 'std-002', 5, 90, 'A', CURRENT_DATE - INTERVAL '7 days', 'mock_exam_platform', CURRENT_TIMESTAMP);

-- Insert assignments
INSERT INTO assignments (assignment_id, student_id, assignment_name, is_completed, due_date, source_system, created_at) VALUES
-- std-001 과제
('asg-001', 'std-001', '수학 문제집 1장', true, CURRENT_DATE - INTERVAL '10 days', 'lms', CURRENT_TIMESTAMP),
('asg-002', 'std-001', '영어 단어 암기', true, CURRENT_DATE - INTERVAL '5 days', 'lms', CURRENT_TIMESTAMP),
('asg-003', 'std-001', '국어 독서록', false, CURRENT_DATE + INTERVAL '5 days', 'lms', CURRENT_TIMESTAMP),
('asg-004', 'std-001', '과학 실험 보고서', true, CURRENT_DATE - INTERVAL '3 days', 'lms', CURRENT_TIMESTAMP),
('asg-005', 'std-001', '사회 요약 정리', false, CURRENT_DATE + INTERVAL '7 days', 'lms', CURRENT_TIMESTAMP),
-- std-002 과제
('asg-006', 'std-002', '수학 문제집 1장', true, CURRENT_DATE - INTERVAL '10 days', 'lms', CURRENT_TIMESTAMP),
('asg-007', 'std-002', '영어 단어 암기', false, CURRENT_DATE - INTERVAL '5 days', 'lms', CURRENT_TIMESTAMP),
('asg-008', 'std-002', '국어 독서록', false, CURRENT_DATE + INTERVAL '5 days', 'lms', CURRENT_TIMESTAMP),
('asg-009', 'std-002', '과학 실험 보고서', true, CURRENT_DATE - INTERVAL '3 days', 'lms', CURRENT_TIMESTAMP),
('asg-010', 'std-002', '사회 요약 정리', true, CURRENT_DATE + INTERVAL '7 days', 'lms', CURRENT_TIMESTAMP);

-- Insert reports
INSERT INTO reports (report_id, student_id, report_type, format, file_path, download_url, generated_at, downloaded_at, created_by, status) VALUES
('rpt-001', 'std-001', 'comprehensive', 'pdf', 'reports/2025/01/rpt-001.pdf', 'https://storage.firebase.com/reports/rpt-001.pdf', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '1 day', 'usr-001', 'completed'),
('rpt-002', 'std-002', 'comprehensive', 'pdf', 'reports/2025/01/rpt-002.pdf', 'https://storage.firebase.com/reports/rpt-002.pdf', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP, 'usr-001', 'completed'),
('rpt-003', 'std-001', 'comprehensive', 'pdf', 'reports/2025/01/rpt-003.pdf', NULL, CURRENT_TIMESTAMP, NULL, 'usr-002', 'processing'),
('rpt-004', 'std-003', 'comprehensive', 'pdf', 'reports/2025/01/rpt-004.pdf', 'https://storage.firebase.com/reports/rpt-004.pdf', CURRENT_TIMESTAMP - INTERVAL '3 days', NULL, 'usr-001', 'completed');

-- Insert report_delivery
INSERT INTO report_delivery (delivery_id, report_id, student_id, parent_email, sent_at, delivery_status) VALUES
('del-001', 'rpt-001', 'std-001', 'parent1@example.com', CURRENT_TIMESTAMP - INTERVAL '1 day', 'success'),
('del-002', 'rpt-002', 'std-002', 'parent2@example.com', CURRENT_TIMESTAMP, 'success'),
('del-003', 'rpt-001', 'std-001', 'parent1@example.com', CURRENT_TIMESTAMP - INTERVAL '2 days', 'failed'),
('del-004', 'rpt-004', 'std-003', 'parent3@example.com', CURRENT_TIMESTAMP - INTERVAL '2 days', 'success');

COMMIT;
```

---

## 11. 추가 제약조건 및 트리거

```sql
-- ============================================
-- Additional Constraints and Triggers
-- ============================================

-- updated_at 자동 업데이트 트리거 함수 (PostgreSQL)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- students 테이블 updated_at 트리거
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- users 테이블 updated_at 트리거
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 리포트 생성 시 자동 이력 저장 트리거 (선택적)
-- CREATE OR REPLACE FUNCTION log_report_generation()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     -- 리포트 생성 이력 로깅 로직
--     RETURN NEW;
-- END;
-- $$ language 'plpgsql';
--
-- CREATE TRIGGER report_generation_log AFTER INSERT ON reports
--     FOR EACH ROW EXECUTE FUNCTION log_report_generation();
```

---

## 12. 뷰 (Views) - 선택적

```sql
-- ============================================
-- Views for Common Queries
-- ============================================

-- 학생별 출석률 뷰
CREATE OR REPLACE VIEW v_student_attendance_rate AS
SELECT 
    s.student_id,
    COUNT(a.attendance_id) FILTER (WHERE a.is_present = true) * 100.0 / NULLIF(COUNT(a.attendance_id), 0) AS attendance_rate,
    COUNT(a.attendance_id) AS total_days,
    COUNT(a.attendance_id) FILTER (WHERE a.is_present = true) AS present_days
FROM students s
LEFT JOIN attendance a ON s.student_id = a.student_id
GROUP BY s.student_id;

-- 학생별 학습 시간 통계 뷰
CREATE OR REPLACE VIEW v_student_study_time_stats AS
SELECT 
    s.student_id,
    AVG(st.hours) AS avg_hours_per_day,
    SUM(st.hours) / NULLIF(COUNT(DISTINCT DATE_TRUNC('week', st.date)), 0) AS avg_hours_per_week,
    SUM(st.hours) AS total_hours
FROM students s
LEFT JOIN study_time st ON s.student_id = st.student_id
GROUP BY s.student_id;

-- 학생별 최근 모의고사 성적 뷰
CREATE OR REPLACE VIEW v_student_recent_mock_exams AS
SELECT DISTINCT ON (student_id)
    student_id,
    exam_round,
    score,
    grade,
    exam_date
FROM mock_exam
ORDER BY student_id, exam_date DESC;
```

---

## 13. 권한 설정 (선택적)

```sql
-- ============================================
-- Role and Permission Setup
-- ============================================

-- 애플리케이션 사용자 역할 생성
-- CREATE ROLE app_user WITH LOGIN PASSWORD 'secure_password_here';
-- 
-- -- 읽기 전용 역할 (리포트 조회용)
-- CREATE ROLE app_readonly WITH LOGIN PASSWORD 'secure_password_here';
-- 
-- -- 권한 부여
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_user;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;
-- 
-- -- 시퀀스 권한 (PostgreSQL)
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
```

---

## 요약

- **총 테이블 수**: 8개
  - users (사용자)
  - students (학생)
  - attendance (출석)
  - study_time (학습 시간)
  - mock_exam (모의고사 성적)
  - assignments (과제)
  - reports (리포트)
  - report_delivery (리포트 전송 이력)

- **인덱스**: 각 테이블별 검색 및 조인 최적화를 위한 인덱스 포함
- **Foreign Keys**: 참조 무결성 보장을 위한 FK 제약조건
- **제약조건**: 데이터 무결성을 위한 CHECK, UNIQUE 제약조건
- **Migration Script**: 전체 스키마 생성 스크립트
- **ORM Entity 정의**: TypeScript/TypeORM 기반 엔티티 정의 설명
- **테스트 데이터**: 개발 및 테스트를 위한 샘플 데이터

모든 스크립트는 PostgreSQL 14+ 기준으로 작성되었으며, MySQL 8.0+로 변환 시 일부 문법 수정이 필요할 수 있습니다.

