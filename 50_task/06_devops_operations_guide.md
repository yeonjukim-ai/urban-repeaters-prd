# DevOps & Operations Guide

본 문서는 Urban Repeaters MVP 시스템의 성능, 보안, 모니터링 Task 및 운영 지침서를 정의한 것입니다.

**기술 스택**: Node.js/Express + Firebase Firestore + Vercel  
**버전**: 1.0.0  
**작성일**: 2025-01-27

---

## 1. Performance Tasks

### 1.1 k6 부하 테스트 스크립트

#### 1.1.1 API 응답 시간 테스트 (REQ-NF-005)

```javascript
// k6/scripts/api_response_time_test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');
const BASE_URL = __ENV.BASE_URL || 'https://api.urban-repeaters.com';

export const options = {
  stages: [
    { duration: '1m', target: 10 },   // 1분간 10명으로 증가
    { duration: '3m', target: 20 },  // 3분간 20명 유지 (REQ-NF-011)
    { duration: '1m', target: 0 },   // 1분간 0명으로 감소
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'], // p95 < 500ms, p99 < 1000ms
    http_req_failed: ['rate<0.01'], // 에러율 < 1%
    errors: ['rate<0.01'],
  },
};

export default function () {
  const token = __ENV.AUTH_TOKEN; // JWT 토큰
  
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };

  // 학생 검색 API 테스트
  const searchResponse = http.get(`${BASE_URL}/api/students?search=test&page=1&limit=20`, {
    headers: headers,
  });
  
  check(searchResponse, {
    '학생 검색 API 응답 시간 < 500ms': (r) => r.timings.duration < 500,
    '학생 검색 API 상태 코드 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  // 학생 상세 조회 API 테스트
  const studentResponse = http.get(`${BASE_URL}/api/students/std-001`, {
    headers: headers,
  });
  
  check(studentResponse, {
    '학생 상세 조회 API 응답 시간 < 500ms': (r) => r.timings.duration < 500,
    '학생 상세 조회 API 상태 코드 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  // 리포트 이력 조회 API 테스트
  const historyResponse = http.get(`${BASE_URL}/api/reports/history?page=1&limit=20`, {
    headers: headers,
  });
  
  check(historyResponse, {
    '리포트 이력 조회 API 응답 시간 < 500ms': (r) => r.timings.duration < 500,
    '리포트 이력 조회 API 상태 코드 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(1);
}
```

#### 1.1.2 동시 리포트 생성 처리 테스트 (REQ-NF-004)

```javascript
// k6/scripts/concurrent_report_generation_test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');
const BASE_URL = __ENV.BASE_URL || 'https://api.urban-repeaters.com';

export const options = {
  stages: [
    { duration: '30s', target: 5 },   // 30초간 5건으로 증가
    { duration: '1m', target: 10 },  // 1분간 10건 유지 (최대 동시 처리)
    { duration: '30s', target: 15 }, // 30초간 15건으로 증가 (초과 요청 테스트)
    { duration: '1m', target: 10 },  // 1분간 10건 유지
    { duration: '30s', target: 0 },  // 30초간 0건으로 감소
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'], // 리포트 생성 요청 응답 < 1초
    http_req_failed: ['rate<0.1'], // 에러율 < 10% (초과 요청 대기열 처리)
    errors: ['rate<0.1'],
  },
};

export default function () {
  const token = __ENV.AUTH_TOKEN;
  
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };

  // 리포트 생성 요청
  const payload = JSON.stringify({
    studentId: 'std-001',
    format: 'pdf',
  });

  const response = http.post(`${BASE_URL}/api/reports/generate`, payload, {
    headers: headers,
  });

  check(response, {
    '리포트 생성 요청 성공': (r) => r.status === 200 || r.status === 202,
    '리포트 생성 요청 응답 시간 < 1초': (r) => r.timings.duration < 1000,
    'reportId 반환': (r) => {
      const body = JSON.parse(r.body);
      return body.reportId !== undefined;
    },
    'status 반환': (r) => {
      const body = JSON.parse(r.body);
      return body.status === 'processing' || body.status === 'completed';
    },
  }) || errorRate.add(1);

  sleep(2);
}
```

#### 1.1.3 리포트 생성 성능 테스트 (REQ-NF-001, REQ-NF-033)

```javascript
// k6/scripts/report_generation_performance_test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend } from 'k6/metrics';

const reportGenerationTime = new Trend('report_generation_time');
const BASE_URL = __ENV.BASE_URL || 'https://api.urban-repeaters.com';

export const options = {
  vus: 5, // 5명의 가상 사용자
  duration: '5m',
  thresholds: {
    report_generation_time: ['p(95)<30000'], // p95 < 30초 (REQ-NF-001)
    http_req_failed: ['rate<0.1'], // 성공률 90% 이상 (REQ-NF-008)
  },
};

export default function () {
  const token = __ENV.AUTH_TOKEN;
  
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };

  // 리포트 생성 요청
  const payload = JSON.stringify({
    studentId: 'std-001',
    format: 'pdf',
  });

  const startTime = Date.now();
  const response = http.post(`${BASE_URL}/api/reports/generate`, payload, {
    headers: headers,
    timeout: '35s', // 30초 + 5초 여유
  });
  const endTime = Date.now();
  const duration = endTime - startTime;

  reportGenerationTime.add(duration);

  check(response, {
    '리포트 생성 성공': (r) => r.status === 200 || r.status === 202,
    '리포트 생성 시간 < 30초': () => duration < 30000,
  });

  // 리포트 상태 확인 (폴링)
  if (response.status === 202) {
    const body = JSON.parse(response.body);
    const reportId = body.reportId;
    
    let status = 'processing';
    let pollCount = 0;
    const maxPolls = 30; // 최대 30회 폴링 (30초)
    
    while (status === 'processing' && pollCount < maxPolls) {
      sleep(1);
      const statusResponse = http.get(`${BASE_URL}/api/reports/${reportId}`, {
        headers: headers,
      });
      
      if (statusResponse.status === 200) {
        const statusBody = JSON.parse(statusResponse.body);
        status = statusBody.status;
      }
      pollCount++;
    }
    
    check(status, {
      '리포트 생성 완료 (30초 이내)': (s) => s === 'completed' || pollCount < 30,
    });
  }

  sleep(5);
}
```

### 1.2 부하 테스트 CI 구성

#### 1.2.1 GitHub Actions Workflow

```yaml
# .github/workflows/load-test.yml
name: Load Test

on:
  schedule:
    - cron: '0 2 * * *' # 매일 오전 2시 실행
  workflow_dispatch: # 수동 실행 가능

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup k6
        uses: grafana/k6-action@v0.3.0
        with:
          k6-version: v0.47.0

      - name: Run API Response Time Test
        run: |
          k6 run k6/scripts/api_response_time_test.js \
            --env BASE_URL=${{ secrets.TEST_API_URL }} \
            --env AUTH_TOKEN=${{ secrets.TEST_AUTH_TOKEN }} \
            --out json=results/api_response_time_$(date +%Y%m%d_%H%M%S).json

      - name: Run Concurrent Report Generation Test
        run: |
          k6 run k6/scripts/concurrent_report_generation_test.js \
            --env BASE_URL=${{ secrets.TEST_API_URL }} \
            --env AUTH_TOKEN=${{ secrets.TEST_AUTH_TOKEN }} \
            --out json=results/concurrent_report_$(date +%Y%m%d_%H%M%S).json

      - name: Run Report Generation Performance Test
        run: |
          k6 run k6/scripts/report_generation_performance_test.js \
            --env BASE_URL=${{ secrets.TEST_API_URL }} \
            --env AUTH_TOKEN=${{ secrets.TEST_AUTH_TOKEN }} \
            --out json=results/report_performance_$(date +%Y%m%d_%H%M%S).json

      - name: Upload test results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: k6-test-results
          path: results/
          retention-days: 30

      - name: Check thresholds
        run: |
          # k6 결과 분석 및 임계값 확인
          # p95 < 500ms, 성공률 > 90% 등
          python scripts/analyze_k6_results.py results/
```

### 1.3 p95 기준 설정

#### 1.3.1 성능 목표 (SLA)

| 메트릭 | p50 (중앙값) | p95 | p99 | 목표 | REQ-NF 참조 |
|--------|-------------|-----|-----|------|------------|
| **API 응답 시간** | < 200ms | < 500ms | < 1000ms | 평균 500ms 이내 | REQ-NF-005 |
| **리포트 생성 시간** | < 15초 | < 30초 | < 35초 | 30초 이내, 달성률 95% 이상 | REQ-NF-001, REQ-NF-033 |
| **학생 검색 API** | < 150ms | < 400ms | < 800ms | 평균 500ms 이내 | REQ-NF-005 |
| **데이터 조회 API** | < 200ms | < 500ms | < 1000ms | 평균 500ms 이내 | REQ-NF-005 |
| **파일 업로드 처리** | < 3초 | < 10초 | < 15초 | 50MB 파일 기준 | REQ-FUNC-015 |

#### 1.3.2 성능 임계값 (Alert 기준)

```yaml
# monitoring/performance_thresholds.yaml
performance_thresholds:
  api_response_time:
    p95_warning: 400ms
    p95_critical: 500ms
    p99_warning: 800ms
    p99_critical: 1000ms
    
  report_generation:
    p95_warning: 25초
    p95_critical: 30초
    p99_warning: 32초
    p99_critical: 35초
    success_rate_warning: 92%
    success_rate_critical: 90% # REQ-NF-008
    
  concurrent_requests:
    max_concurrent: 10 # REQ-NF-004
    queue_size_warning: 5
    queue_size_critical: 10
```

### 1.4 APM 지표 정의

#### 1.4.1 주요 APM 지표

```yaml
# monitoring/apm_metrics.yaml
apm_metrics:
  # 응답 시간 지표
  response_time:
    - metric: http.request.duration
      aggregation: p95, p99, avg
      tags: [endpoint, method, status_code]
      
  # 처리량 지표
  throughput:
    - metric: http.request.count
      aggregation: rate
      tags: [endpoint, method, status_code]
      
  # 에러율 지표
  error_rate:
    - metric: http.request.error_rate
      aggregation: rate
      tags: [endpoint, method, error_type]
      
  # 리포트 생성 지표
  report_generation:
    - metric: report.generation.duration
      aggregation: p95, p99, avg, max
      tags: [student_id, format, status]
    - metric: report.generation.success_rate
      aggregation: rate
      tags: [format]
    - metric: report.generation.queue_size
      aggregation: gauge
      
  # Firestore 쿼리 지표
  firestore_queries:
    - metric: firestore.query.duration
      aggregation: p95, p99, avg
      tags: [collection, operation]
    - metric: firestore.query.count
      aggregation: rate
      tags: [collection, operation]
      
  # Vercel 함수 지표
  vercel_functions:
    - metric: vercel.function.duration
      aggregation: p95, p99, avg, max
      tags: [function_name, region]
    - metric: vercel.function.invocations
      aggregation: rate
      tags: [function_name, status]
    - metric: vercel.function.errors
      aggregation: rate
      tags: [function_name, error_type]
```

#### 1.4.2 APM 대시보드 구성

```yaml
# monitoring/apm_dashboard.yaml
dashboard:
  name: "Urban Repeaters APM Dashboard"
  widgets:
    - title: "API 응답 시간 (p95)"
      type: timeseries
      metrics:
        - http.request.duration.p95
      thresholds:
        warning: 400ms
        critical: 500ms
        
    - title: "리포트 생성 성능"
      type: timeseries
      metrics:
        - report.generation.duration.p95
        - report.generation.success_rate
      thresholds:
        duration_warning: 25초
        duration_critical: 30초
        success_rate_warning: 92%
        success_rate_critical: 90%
        
    - title: "동시 사용자 수"
      type: gauge
      metrics:
        - concurrent.users.count
      thresholds:
        warning: 15
        critical: 20 # REQ-NF-011
        
    - title: "에러율"
      type: timeseries
      metrics:
        - http.request.error_rate
      thresholds:
        warning: 1%
        critical: 5%
```

---

## 2. Security Tasks

### 2.1 OAuth2 Scopes

#### 2.1.1 Scope 정의

```yaml
# security/oauth2_scopes.yaml
oauth2_scopes:
  # 읽기 권한
  read:students:
    description: "학생 정보 조회"
    endpoints:
      - GET /api/students
      - GET /api/students/{studentId}
      
  read:reports:
    description: "리포트 조회 및 다운로드"
    endpoints:
      - GET /api/reports/history
      - GET /api/reports/{reportId}/download
      - GET /api/reports/delivery/history
      
  read:dashboard:
    description: "통합 대시보드 조회"
    endpoints:
      - GET /api/integrations/dashboard
      
  # 쓰기 권한
  write:reports:
    description: "리포트 생성"
    endpoints:
      - POST /api/reports/generate
      
  write:integrations:
    description: "데이터 통합 (파일 업로드, 수동 입력)"
    endpoints:
      - POST /api/integrations/upload
      - POST /api/integrations/manual
      
  write:reports:send:
    description: "리포트 이메일 전송"
    endpoints:
      - POST /api/reports/{reportId}/send-email
      
  # 기본 권한 (모든 로그인 사용자)
  default_scopes:
    - read:students
    - read:reports
    - read:dashboard
    - write:reports
    - write:integrations
    - write:reports:send
```

#### 2.1.2 Scope 검증 미들웨어

```typescript
// src/middleware/scopeValidation.ts
import { Request, Response, NextFunction } from 'express';

const requiredScopes: Record<string, string[]> = {
  'GET /api/students': ['read:students'],
  'GET /api/students/:studentId': ['read:students'],
  'POST /api/reports/generate': ['write:reports'],
  'GET /api/reports/history': ['read:reports'],
  'GET /api/reports/:reportId/download': ['read:reports'],
  'POST /api/reports/:reportId/send-email': ['write:reports:send'],
  'POST /api/integrations/upload': ['write:integrations'],
  'POST /api/integrations/manual': ['write:integrations'],
  'GET /api/integrations/dashboard': ['read:dashboard'],
};

export function validateScope(req: Request, res: Response, next: NextFunction) {
  const method = req.method;
  const path = req.route?.path || req.path;
  const key = `${method} ${path}`;
  
  const scopes = req.user?.scopes || [];
  const required = requiredScopes[key] || [];
  
  const hasScope = required.every(scope => scopes.includes(scope));
  
  if (!hasScope) {
    return res.status(403).json({
      errorCode: 'SECURITY_001',
      message: '권한이 없습니다. 필요한 스코프: ' + required.join(', '),
    });
  }
  
  next();
}
```

### 2.2 RBAC (Role-Based Access Control)

#### 2.2.1 역할 정의

```yaml
# security/rbac_roles.yaml
rbac_roles:
  # MVP에서는 단일 관리자 역할만 사용 (REQ-FUNC-037)
  # Post-MVP에서 확장 예정
  admin:
    description: "시스템 관리자 (모든 권한)"
    permissions:
      - "*" # 모든 권한
    scopes:
      - read:students
      - read:reports
      - read:dashboard
      - write:reports
      - write:integrations
      - write:reports:send
      
  # Post-MVP 역할 (참고용)
  manager:
    description: "학사 관리자"
    permissions:
      - read:students
      - read:reports
      - read:dashboard
      - write:reports
      - write:reports:send
    scopes:
      - read:students
      - read:reports
      - read:dashboard
      - write:reports
      - write:reports:send
      
  operator:
    description: "운영 관리자"
    permissions:
      - read:students
      - read:dashboard
      - write:integrations
    scopes:
      - read:students
      - read:dashboard
      - write:integrations
```

#### 2.2.2 RBAC 구현 (Post-MVP용)

```typescript
// src/middleware/rbac.ts (Post-MVP용)
import { Request, Response, NextFunction } from 'express';

const rolePermissions: Record<string, string[]> = {
  admin: ['*'],
  manager: ['read:students', 'read:reports', 'read:dashboard', 'write:reports', 'write:reports:send'],
  operator: ['read:students', 'read:dashboard', 'write:integrations'],
};

export function checkPermission(requiredPermission: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    const userRole = req.user?.role || 'admin'; // MVP: 모든 사용자는 admin
    const permissions = rolePermissions[userRole] || [];
    
    const hasPermission = permissions.includes('*') || permissions.includes(requiredPermission);
    
    if (!hasPermission) {
      return res.status(403).json({
        errorCode: 'SECURITY_002',
        message: '권한이 없습니다.',
      });
    }
    
    next();
  };
}
```

### 2.3 TLS 1.2+ 설정

#### 2.3.1 TLS 설정

```yaml
# security/tls_config.yaml
tls_config:
  minimum_version: "1.2"
  preferred_version: "1.3"
  cipher_suites:
    - TLS_AES_256_GCM_SHA384
    - TLS_CHACHA20_POLY1305_SHA256
    - TLS_AES_128_GCM_SHA256
    - ECDHE-RSA-AES256-GCM-SHA384
    - ECDHE-RSA-AES128-GCM-SHA256
    
  # Vercel 기본 설정 활용
  vercel:
    https_enforced: true
    hsts_enabled: true
    hsts_max_age: 31536000 # 1년
```

#### 2.3.2 TLS 검증 스크립트

```bash
#!/bin/bash
# scripts/security/verify_tls.sh

BASE_URL="${1:-https://api.urban-repeaters.com}"

echo "TLS 검증: $BASE_URL"

# TLS 버전 확인
echo "=== TLS 버전 확인 ==="
openssl s_client -connect $(echo $BASE_URL | sed 's|https://||' | cut -d/ -f1):443 -tls1_2 < /dev/null 2>&1 | grep -i "protocol"
openssl s_client -connect $(echo $BASE_URL | sed 's|https://||' | cut -d/ -f1):443 -tls1_3 < /dev/null 2>&1 | grep -i "protocol"

# 인증서 정보 확인
echo "=== 인증서 정보 ==="
echo | openssl s_client -showcerts -servername $(echo $BASE_URL | sed 's|https://||' | cut -d/ -f1) -connect $(echo $BASE_URL | sed 's|https://||' | cut -d/ -f1):443 2>/dev/null | openssl x509 -inform pem -noout -text | grep -A 2 "Validity"

# HSTS 확인
echo "=== HSTS 헤더 확인 ==="
curl -I $BASE_URL 2>&1 | grep -i "strict-transport-security"

# SSL Labs API 검증 (선택적)
echo "=== SSL Labs 검증 ==="
# curl "https://api.ssllabs.com/api/v3/analyze?host=$(echo $BASE_URL | sed 's|https://||' | cut -d/ -f1)" | jq '.endpoints[0].grade'
```

### 2.4 감사 로그 스키마

#### 2.4.1 감사 로그 데이터 모델

```typescript
// src/models/auditLog.ts
interface AuditLog {
  auditId: string; // UUID
  timestamp: Date;
  userId: string;
  userEmail: string;
  action: string; // 'CREATE', 'READ', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'DOWNLOAD', 'SEND_EMAIL'
  resource: string; // 'student', 'report', 'integration', 'user'
  resourceId?: string;
  endpoint: string; // '/api/students'
  method: string; // 'GET', 'POST', 'PUT', 'DELETE'
  ipAddress: string;
  userAgent: string;
  requestBody?: object; // 민감 정보 제외
  responseStatus: number;
  errorCode?: string;
  duration: number; // ms
  metadata?: {
    studentId?: string;
    reportId?: string;
    fileSize?: number;
    emailRecipient?: string; // 암호화된 이메일
  };
}
```

#### 2.4.2 감사 로그 저장 스키마 (Firestore)

```typescript
// Firestore 컬렉션: audit_logs
{
  auditId: string (문서 ID),
  timestamp: Timestamp,
  userId: string,
  userEmail: string (암호화),
  action: string,
  resource: string,
  resourceId: string (optional),
  endpoint: string,
  method: string,
  ipAddress: string,
  userAgent: string,
  requestBody: object (optional, 민감 정보 제외),
  responseStatus: number,
  errorCode: string (optional),
  duration: number,
  metadata: object (optional)
}
```

#### 2.4.3 감사 로그 미들웨어

```typescript
// src/middleware/auditLog.ts
import { Request, Response, NextFunction } from 'express';
import { admin } from 'firebase-admin';

const auditLogCollection = admin.firestore().collection('audit_logs');

export async function auditLog(req: Request, res: Response, next: NextFunction) {
  const startTime = Date.now();
  const originalSend = res.send;
  
  res.send = function(body: any) {
    const duration = Date.now() - startTime;
    
    // 비동기로 감사 로그 저장 (응답에 영향 없도록)
    setImmediate(async () => {
      try {
        const auditLog = {
          auditId: admin.firestore().collection('audit_logs').doc().id,
          timestamp: admin.firestore.Timestamp.now(),
          userId: req.user?.userId || 'anonymous',
          userEmail: req.user?.email || 'anonymous',
          action: getActionFromMethod(req.method),
          resource: getResourceFromPath(req.path),
          resourceId: req.params.id || req.params.studentId || req.params.reportId,
          endpoint: req.path,
          method: req.method,
          ipAddress: req.ip || req.headers['x-forwarded-for'] || 'unknown',
          userAgent: req.headers['user-agent'] || 'unknown',
          requestBody: sanitizeRequestBody(req.body),
          responseStatus: res.statusCode,
          errorCode: body.errorCode,
          duration: duration,
          metadata: extractMetadata(req),
        };
        
        await auditLogCollection.add(auditLog);
      } catch (error) {
        console.error('감사 로그 저장 실패:', error);
        // 감사 로그 실패는 시스템에 영향 없도록
      }
    });
    
    return originalSend.call(this, body);
  };
  
  next();
}

function getActionFromMethod(method: string): string {
  const mapping: Record<string, string> = {
    'GET': 'READ',
    'POST': 'CREATE',
    'PUT': 'UPDATE',
    'PATCH': 'UPDATE',
    'DELETE': 'DELETE',
  };
  return mapping[method] || 'UNKNOWN';
}

function getResourceFromPath(path: string): string {
  if (path.includes('/students')) return 'student';
  if (path.includes('/reports')) return 'report';
  if (path.includes('/integrations')) return 'integration';
  if (path.includes('/auth')) return 'user';
  return 'unknown';
}

function sanitizeRequestBody(body: any): any {
  if (!body) return undefined;
  
  const sanitized = { ...body };
  // 민감 정보 제거
  delete sanitized.password;
  delete sanitized.token;
  delete sanitized.apiKey;
  
  return sanitized;
}

function extractMetadata(req: Request): any {
  const metadata: any = {};
  
  if (req.params.studentId) metadata.studentId = req.params.studentId;
  if (req.params.reportId) metadata.reportId = req.params.reportId;
  if (req.body?.parentEmail) metadata.emailRecipient = req.body.parentEmail; // 암호화 필요
  if (req.file) metadata.fileSize = req.file.size;
  
  return metadata;
}
```

### 2.5 취약점 스캔

#### 2.5.1 취약점 스캔 스크립트

```bash
#!/bin/bash
# scripts/security/vulnerability_scan.sh

echo "=== 취약점 스캔 시작 ==="

# 1. npm audit (의존성 취약점)
echo "=== npm audit ==="
npm audit --audit-level=moderate

# 2. Snyk 스캔 (선택적)
# echo "=== Snyk 스캔 ==="
# npx snyk test

# 3. OWASP ZAP 스캔 (선택적)
# echo "=== OWASP ZAP 스캔 ==="
# docker run -t owasp/zap2docker-stable zap-baseline.py -t https://api.urban-repeaters.com

# 4. SSL/TLS 취약점 확인
echo "=== SSL/TLS 취약점 확인 ==="
./scripts/security/verify_tls.sh

# 5. 헤더 보안 확인
echo "=== 보안 헤더 확인 ==="
curl -I https://api.urban-repeaters.com 2>&1 | grep -E "(X-Frame-Options|X-Content-Type-Options|X-XSS-Protection|Strict-Transport-Security|Content-Security-Policy)"

echo "=== 취약점 스캔 완료 ==="
```

#### 2.5.2 취약점 스캔 CI 구성

```yaml
# .github/workflows/security-scan.yml
name: Security Scan

on:
  schedule:
    - cron: '0 3 * * 1' # 매주 월요일 오전 3시
  workflow_dispatch:

jobs:
  vulnerability-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Run npm audit
        run: npm audit --audit-level=moderate
        continue-on-error: true

      - name: Run Snyk scan
        uses: snyk/actions/node@master
        continue-on-error: true
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

      - name: Check TLS configuration
        run: ./scripts/security/verify_tls.sh ${{ secrets.PRODUCTION_URL }}

      - name: Upload scan results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: security-scan-results
          path: |
            npm-audit-results.json
            snyk-results.json
```

---

## 3. Monitoring Tasks

### 3.1 CloudWatch/Prometheus Alerts

#### 3.1.1 CloudWatch Alarms (AWS 기준, Vercel은 Vercel 로그 사용)

```yaml
# monitoring/cloudwatch_alarms.yaml
cloudwatch_alarms:
  # API 응답 시간 알림
  api_response_time_high:
    metric: APIResponseTime
    namespace: UrbanRepeaters/API
    statistic: p95
    threshold: 500 # ms (REQ-NF-005)
    comparison: GreaterThanThreshold
    evaluation_periods: 2
    period: 300 # 5분
    alarm_actions:
      - sns_topic: api-alerts
    
  # 리포트 생성 성공률 알림
  report_generation_success_rate_low:
    metric: ReportGenerationSuccessRate
    namespace: UrbanRepeaters/Reports
    statistic: Average
    threshold: 0.90 # 90% (REQ-NF-008)
    comparison: LessThanThreshold
    evaluation_periods: 3
    period: 300
    alarm_actions:
      - sns_topic: report-alerts
    
  # 리포트 생성 시간 알림
  report_generation_time_high:
    metric: ReportGenerationTime
    namespace: UrbanRepeaters/Reports
    statistic: p95
    threshold: 30000 # 30초 (REQ-NF-001)
    comparison: GreaterThanThreshold
    evaluation_periods: 2
    period: 300
    alarm_actions:
      - sns_topic: report-alerts
    
  # 동시 사용자 수 알림
  concurrent_users_high:
    metric: ConcurrentUsers
    namespace: UrbanRepeaters/System
    statistic: Maximum
    threshold: 20 # REQ-NF-011
    comparison: GreaterThanThreshold
    evaluation_periods: 1
    period: 60
    alarm_actions:
      - sns_topic: system-alerts
    
  # 에러율 알림
  error_rate_high:
    metric: ErrorRate
    namespace: UrbanRepeaters/API
    statistic: Average
    threshold: 0.05 # 5%
    comparison: GreaterThanThreshold
    evaluation_periods: 2
    period: 300
    alarm_actions:
      - sns_topic: critical-alerts
```

#### 3.1.2 Prometheus Alerts (선택적, 자체 모니터링용)

```yaml
# monitoring/prometheus_alerts.yaml
groups:
  - name: urban_repeaters_alerts
    interval: 30s
    rules:
      # API 응답 시간 알림
      - alert: HighAPIResponseTime
        expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "API 응답 시간이 높습니다 (p95 > 500ms)"
          description: "{{ $labels.endpoint }}의 p95 응답 시간이 500ms를 초과했습니다."
          
      # 리포트 생성 성공률 알림
      - alert: LowReportGenerationSuccessRate
        expr: rate(report_generation_success_total[5m]) / rate(report_generation_total[5m]) < 0.90
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "리포트 생성 성공률이 낮습니다 (< 90%)"
          description: "리포트 생성 성공률이 90% 미만입니다. (REQ-NF-008)"
          
      # 리포트 생성 시간 알림
      - alert: HighReportGenerationTime
        expr: histogram_quantile(0.95, report_generation_duration_seconds_bucket) > 30
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "리포트 생성 시간이 높습니다 (p95 > 30초)"
          description: "리포트 생성 p95 시간이 30초를 초과했습니다. (REQ-NF-001)"
          
      # 동시 사용자 수 알림
      - alert: HighConcurrentUsers
        expr: concurrent_users > 20
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "동시 사용자 수가 높습니다 (> 20명)"
          description: "동시 사용자 수가 20명을 초과했습니다. (REQ-NF-011)"
          
      # 에러율 알림
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "에러율이 높습니다 (> 5%)"
          description: "API 에러율이 5%를 초과했습니다."
```

### 3.2 로그 포맷 규칙

#### 3.2.1 구조화된 로그 포맷

```typescript
// src/utils/logger.ts
import winston from 'winston';

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.json(),
  winston.format.printf((info) => {
    const log: any = {
      timestamp: info.timestamp,
      level: info.level,
      message: info.message,
      service: 'urban-repeaters-api',
      environment: process.env.NODE_ENV || 'development',
      version: process.env.APP_VERSION || '1.0.0',
    };
    
    // 컨텍스트 정보 추가
    if (info.requestId) log.requestId = info.requestId;
    if (info.userId) log.userId = info.userId;
    if (info.endpoint) log.endpoint = info.endpoint;
    if (info.method) log.method = info.method;
    if (info.statusCode) log.statusCode = info.statusCode;
    if (info.duration) log.duration = info.duration;
    if (info.error) {
      log.error = {
        code: info.error.code,
        message: info.error.message,
        stack: info.error.stack,
      };
    }
    
    return JSON.stringify(log);
  })
);

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  transports: [
    new winston.transports.Console(),
    // Vercel 로그는 자동으로 수집됨
  ],
});
```

#### 3.2.2 로그 레벨 규칙

```yaml
# monitoring/log_levels.yaml
log_levels:
  # ERROR: 시스템 오류, 복구 불가능한 에러
  error:
    examples:
      - "Firestore 연결 실패"
      - "PDF 생성 실패"
      - "이메일 전송 실패"
    actions:
      - 알림 전송
      - 에러 추적 시스템에 기록
      
  # WARN: 경고, 주의 필요하지만 시스템은 동작
  warn:
    examples:
      - "API 응답 시간이 500ms 초과"
      - "리포트 생성 시간이 25초 초과"
      - "동시 사용자 수가 15명 초과"
    actions:
      - 모니터링 대시보드에 표시
      
  # INFO: 주요 이벤트, 비즈니스 로직 실행
  info:
    examples:
      - "리포트 생성 요청"
      - "파일 업로드 완료"
      - "이메일 전송 완료"
      - "사용자 로그인"
    actions:
      - 로그 수집
      
  # DEBUG: 디버깅 정보 (개발 환경에서만)
  debug:
    examples:
      - "Firestore 쿼리 실행"
      - "데이터 검증 과정"
      - "템플릿 렌더링"
    actions:
      - 개발 환경에서만 활성화
```

### 3.3 SLA 지표

#### 3.3.1 SLA 정의

```yaml
# monitoring/sla_metrics.yaml
sla_metrics:
  # 시스템 가동률 (REQ-NF-006)
  uptime:
    target: 95% # 연간 가동률
    measurement_period: 1 year
    exclusion: "계획된 유지보수 시간"
    monitoring:
      - metric: system.uptime
      - alert_threshold: 94%
      
  # API 응답 시간 (REQ-NF-005)
  api_response_time:
    target: "평균 500ms 이내"
    p95_target: 500ms
    p99_target: 1000ms
    measurement_period: 1 day
    monitoring:
      - metric: http.request.duration.p95
      - alert_threshold: 500ms
      
  # 리포트 생성 성능 (REQ-NF-001, REQ-NF-033)
  report_generation:
    target: "30초 이내, 달성률 95% 이상"
    p95_target: 30초
    success_rate_target: 95%
    measurement_period: 1 day
    monitoring:
      - metric: report.generation.duration.p95
      - metric: report.generation.success_rate
      - alert_thresholds:
          duration: 30초
          success_rate: 95%
          
  # 리포트 생성 성공률 (REQ-NF-008)
  report_generation_success_rate:
    target: 90% 이상
    measurement_period: 1 day
    monitoring:
      - metric: report.generation.success_rate
      - alert_threshold: 90%
      
  # 데이터 통합 정확도 (REQ-NF-007)
  data_integration_accuracy:
    target: 99% 이상
    measurement_period: 1 week
    monitoring:
      - metric: data.integration.accuracy
      - alert_threshold: 99%
```

#### 3.3.2 SLA 모니터링 대시보드

```yaml
# monitoring/sla_dashboard.yaml
sla_dashboard:
  name: "Urban Repeaters SLA Dashboard"
  refresh_interval: 60s
  widgets:
    - title: "시스템 가동률"
      type: gauge
      metric: system.uptime
      target: 95%
      current_period: "이번 달"
      
    - title: "API 응답 시간 (p95)"
      type: timeseries
      metric: http.request.duration.p95
      target: 500ms
      current_value: "실시간"
      
    - title: "리포트 생성 성능"
      type: timeseries
      metrics:
        - report.generation.duration.p95
        - report.generation.success_rate
      targets:
        duration: 30초
        success_rate: 95%
        
    - title: "리포트 생성 성공률"
      type: gauge
      metric: report.generation.success_rate
      target: 90%
      current_period: "오늘"
      
    - title: "데이터 통합 정확도"
      type: gauge
      metric: data.integration.accuracy
      target: 99%
      current_period: "이번 주"
```

---

## 4. 운영 지침서

### 4.1 장애 대응 절차

#### 4.1.1 장애 등급 정의

```yaml
# operations/incident_severity.yaml
incident_severity:
  # Critical (P0): 시스템 전체 중단
  critical:
    description: "시스템 전체가 사용 불가능한 상태"
    examples:
      - "모든 API 엔드포인트 응답 불가"
      - "Firestore 연결 완전 실패"
      - "Vercel 서비스 중단"
    response_time: "즉시 (15분 이내)"
    resolution_time: "1시간 이내"
    escalation: "즉시 CTO/기술 리드에게 알림"
    
  # High (P1): 주요 기능 중단
  high:
    description: "주요 기능이 사용 불가능한 상태"
    examples:
      - "리포트 생성 기능 완전 실패"
      - "데이터 통합 기능 실패"
      - "로그인 기능 실패"
    response_time: "30분 이내"
    resolution_time: "4시간 이내"
    escalation: "1시간 내 해결되지 않으면 상급자에게 알림"
    
  # Medium (P2): 부분 기능 저하
  medium:
    description: "일부 기능이 저하되었지만 우회 가능"
    examples:
      - "리포트 생성 성공률 80-90% (목표 90%)"
      - "API 응답 시간 500-1000ms (목표 500ms)"
      - "특정 엔드포인트 간헐적 실패"
    response_time: "2시간 이내"
    resolution_time: "24시간 이내"
    escalation: "24시간 내 해결되지 않으면 알림"
    
  # Low (P3): 경미한 문제
  low:
    description: "성능 저하 또는 경미한 문제"
    examples:
      - "리포트 생성 시간 25-30초 (목표 30초)"
      - "일부 에러 메시지 개선 필요"
    response_time: "1일 이내"
    resolution_time: "1주일 이내"
    escalation: "없음"
```

#### 4.1.2 장애 대응 절차

```markdown
# operations/incident_response_procedure.md

## 장애 대응 절차

### 1. 장애 감지
- 모니터링 알림 수신
- 사용자 신고 접수
- 로그 분석 중 발견

### 2. 장애 등급 판단
- Critical/High/Medium/Low 등급 결정
- 등급에 따른 대응 팀 구성

### 3. 초기 대응
- 장애 현상 확인
- 영향 범위 파악
- 임시 조치 (우회 방법) 적용

### 4. 원인 분석
- 로그 분석
- 메트릭 확인
- 재현 시도

### 5. 해결 조치
- 근본 원인 해결
- 시스템 복구
- 검증 테스트

### 6. 사후 처리
- 장애 보고서 작성
- 근본 원인 분석 (RCA)
- 재발 방지 대책 수립

### 7. 커뮤니케이션
- 사용자 공지 (필요 시)
- 팀 내 공유
- 경영진 보고 (Critical/High)
```

#### 4.1.3 장애 대응 체크리스트

```markdown
# operations/incident_response_checklist.md

## 장애 대응 체크리스트

### Critical (P0) 장애
- [ ] 장애 등급 확인 및 팀 알림
- [ ] CTO/기술 리드에게 즉시 알림
- [ ] 장애 현상 및 영향 범위 파악
- [ ] 임시 조치 (우회 방법) 적용
- [ ] 원인 분석 시작
- [ ] 해결 조치 실행
- [ ] 시스템 복구 확인
- [ ] 사용자 공지 (필요 시)
- [ ] 장애 보고서 작성 (24시간 이내)

### High (P1) 장애
- [ ] 장애 등급 확인 및 팀 알림
- [ ] 장애 현상 및 영향 범위 파악
- [ ] 임시 조치 (우회 방법) 적용
- [ ] 원인 분석
- [ ] 해결 조치 실행
- [ ] 시스템 복구 확인
- [ ] 장애 보고서 작성 (48시간 이내)

### Medium (P2) 장애
- [ ] 장애 현상 확인
- [ ] 원인 분석
- [ ] 해결 조치 계획 수립
- [ ] 해결 조치 실행
- [ ] 검증 및 모니터링
- [ ] 이슈 트래킹 시스템에 기록

### Low (P3) 장애
- [ ] 이슈 트래킹 시스템에 기록
- [ ] 우선순위에 따라 해결 계획 수립
- [ ] 해결 조치 실행
```

### 4.2 백업 정책

#### 4.2.1 데이터 백업 전략

```yaml
# operations/backup_policy.yaml
backup_policy:
  # Firestore 백업
  firestore:
    frequency: "매일 오전 2시 (UTC)"
    retention: 30일
    backup_type: "전체 백업"
    storage_location: "Firebase Storage / Google Cloud Storage"
    restore_time_objective: "1시간 이내"
    restore_point_objective: "24시간"
    
  # Firebase Storage 백업 (리포트 PDF)
  storage:
    frequency: "매일 오전 3시 (UTC)"
    retention: 90일
    backup_type: "증분 백업"
    storage_location: "Google Cloud Storage (다른 리전)"
    restore_time_objective: "2시간 이내"
    restore_point_objective: "24시간"
    
  # 설정 및 코드 백업
  configuration:
    frequency: "변경 시마다"
    retention: "무제한"
    backup_type: "버전 관리 (Git)"
    storage_location: "GitHub Repository"
    restore_time_objective: "즉시"
    restore_point_objective: "변경 이력 전체"
    
  # 백업 검증
  verification:
    frequency: "주 1회"
    method: "샘플 데이터 복원 테스트"
    success_criteria: "복원된 데이터 무결성 검증"
```

#### 4.2.2 백업 스크립트

```bash
#!/bin/bash
# scripts/backup/firestore_backup.sh

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_BUCKET="gs://urban-repeaters-backups/firestore"
PROJECT_ID="urban-repeaters-prod"

echo "Firestore 백업 시작: $BACKUP_DATE"

# Firestore 백업 실행
gcloud firestore export gs://${BACKUP_BUCKET}/${BACKUP_DATE} \
  --project=${PROJECT_ID}

if [ $? -eq 0 ]; then
  echo "Firestore 백업 성공: $BACKUP_DATE"
  
  # 백업 메타데이터 저장
  echo "{
    \"backup_date\": \"$BACKUP_DATE\",
    \"backup_type\": \"firestore\",
    \"status\": \"success\",
    \"location\": \"${BACKUP_BUCKET}/${BACKUP_DATE}\"
  }" > /tmp/backup_metadata_${BACKUP_DATE}.json
  
  # 메타데이터를 Firestore에 저장
  # (백업 이력 추적용)
else
  echo "Firestore 백업 실패: $BACKUP_DATE"
  # 알림 전송
  exit 1
fi
```

#### 4.2.3 백업 복원 절차

```markdown
# operations/backup_restore_procedure.md

## 백업 복원 절차

### 1. 복원 필요성 확인
- 데이터 손실 범위 파악
- 복원 시점 결정
- 복원 대상 데이터 확인

### 2. 복원 전 준비
- 현재 시스템 상태 백업 (복원 실패 대비)
- 복원 대상 환경 준비 (스테이징 또는 프로덕션)
- 복원 계획 수립

### 3. 복원 실행
- Firestore 백업 복원
  ```bash
  gcloud firestore import gs://backup-bucket/backup-date \
    --project=urban-repeaters-prod
  ```
- Firebase Storage 백업 복원
  ```bash
  gsutil -m cp -r gs://backup-bucket/storage/backup-date/* \
    gs://urban-repeaters-storage/
  ```

### 4. 복원 검증
- 데이터 무결성 검증
- 샘플 데이터 확인
- 기능 테스트

### 5. 복원 완료
- 시스템 정상 동작 확인
- 사용자 공지 (필요 시)
- 복원 보고서 작성
```

### 4.3 배포/릴리즈 전략

#### 4.3.1 배포 환경

```yaml
# operations/deployment_environments.yaml
deployment_environments:
  # 개발 환경
  development:
    url: "https://dev.urban-repeaters.com"
    purpose: "개발 및 단위 테스트"
    deployment: "자동 (main 브랜치 push 시)"
    data: "더미 데이터"
    
  # 스테이징 환경
  staging:
    url: "https://staging.urban-repeaters.com"
    purpose: "통합 테스트 및 QA"
    deployment: "자동 (release/* 브랜치 push 시)"
    data: "프로덕션 데이터 복사본 (익명화)"
    
  # 프로덕션 환경
  production:
    url: "https://api.urban-repeaters.com"
    purpose: "실제 서비스"
    deployment: "수동 승인 필요"
    data: "실제 프로덕션 데이터"
```

#### 4.3.2 배포 파이프라인

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches:
      - main # 개발 환경 자동 배포
      - release/* # 스테이징 환경 자동 배포
  workflow_dispatch: # 프로덕션 수동 배포

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run test
      - run: npm run lint
      - run: npm run build

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm audit --audit-level=moderate

  deploy-dev:
    if: github.ref == 'refs/heads/main'
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID_DEV }}
          vercel-args: '--prod'
          scope: ${{ secrets.VERCEL_ORG_ID }}

  deploy-staging:
    if: startsWith(github.ref, 'refs/heads/release/')
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID_STAGING }}
          vercel-args: '--prod'
          scope: ${{ secrets.VERCEL_ORG_ID }}

  deploy-production:
    if: github.event_name == 'workflow_dispatch'
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://api.urban-repeaters.com
    steps:
      - uses: actions/checkout@v3
      - uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID_PROD }}
          vercel-args: '--prod'
          scope: ${{ secrets.VERCEL_ORG_ID }}
```

#### 4.3.3 릴리즈 전 체크리스트

```markdown
# operations/release_checklist.md

## 릴리즈 전 체크리스트

### 코드 품질
- [ ] 모든 테스트 통과 (단위 테스트, 통합 테스트)
- [ ] 린터 오류 없음
- [ ] 코드 리뷰 완료
- [ ] 보안 스캔 통과

### 성능
- [ ] 부하 테스트 통과 (k6)
- [ ] API 응답 시간 목표 달성 (p95 < 500ms)
- [ ] 리포트 생성 성능 목표 달성 (p95 < 30초, 달성률 95% 이상)

### 보안
- [ ] 취약점 스캔 통과
- [ ] TLS 설정 확인
- [ ] 인증/인가 로직 검증
- [ ] 개인정보 암호화 확인

### 문서
- [ ] API 문서 업데이트
- [ ] 변경 사항 문서화
- [ ] 릴리즈 노트 작성

### 배포
- [ ] 스테이징 환경 배포 및 검증
- [ ] 롤백 계획 수립
- [ ] 모니터링 대시보드 확인
- [ ] 알림 설정 확인

### 프로덕션 배포
- [ ] 프로덕션 배포 승인
- [ ] 배포 실행
- [ ] 배포 후 검증
- [ ] 모니터링 강화 (배포 후 1시간)
```

#### 4.3.4 롤백 절차

```markdown
# operations/rollback_procedure.md

## 롤백 절차

### 1. 롤백 필요성 판단
- 장애 등급 확인 (Critical/High)
- 영향 범위 파악
- 롤백 vs 핫픽스 결정

### 2. 롤백 실행
- Vercel 이전 버전으로 롤백
  ```bash
  vercel rollback [deployment-url]
  ```
- 또는 Git 태그를 사용한 롤백
  ```bash
  git checkout [previous-stable-tag]
  vercel --prod
  ```

### 3. 롤백 검증
- 시스템 정상 동작 확인
- 주요 기능 테스트
- 모니터링 지표 확인

### 4. 사후 처리
- 롤백 원인 분석
- 재배포 계획 수립
- 롤백 보고서 작성
```

---

## 5. 운영 체크리스트

### 5.1 일일 운영 체크리스트

```markdown
# operations/daily_checklist.md

## 일일 운영 체크리스트

### 모니터링 확인
- [ ] 시스템 가동률 확인 (목표: 95% 이상)
- [ ] API 응답 시간 확인 (목표: p95 < 500ms)
- [ ] 리포트 생성 성공률 확인 (목표: 90% 이상)
- [ ] 에러율 확인 (목표: < 5%)
- [ ] 동시 사용자 수 확인 (목표: < 20명)

### 로그 확인
- [ ] 에러 로그 확인
- [ ] 경고 로그 확인
- [ ] 비정상 패턴 확인

### 백업 확인
- [ ] 전일 백업 성공 여부 확인
- [ ] 백업 파일 무결성 검증 (주 1회)
```

### 5.2 주간 운영 체크리스트

```markdown
# operations/weekly_checklist.md

## 주간 운영 체크리스트

### 성능 분석
- [ ] 주간 성능 리포트 작성
- [ ] SLA 달성률 확인
- [ ] 성능 트렌드 분석

### 보안
- [ ] 취약점 스캔 실행
- [ ] 보안 로그 검토
- [ ] 접근 권한 검토

### 백업 검증
- [ ] 백업 복원 테스트 (샘플 데이터)
- [ ] 백업 보관 정책 준수 확인
```

### 5.3 월간 운영 체크리스트

```markdown
# operations/monthly_checklist.md

## 월간 운영 체크리스트

### SLA 리포트
- [ ] 월간 SLA 달성률 리포트
- [ ] 장애 통계 및 분석
- [ ] 개선 사항 도출

### 용량 계획
- [ ] 데이터 증가율 분석
- [ ] 저장 공간 사용량 확인
- [ ] 확장 필요성 검토

### 보안 감사
- [ ] 보안 감사 로그 검토
- [ ] 접근 권한 재검토
- [ ] 보안 정책 준수 확인
```

---

## 6. 요약

### 6.1 Performance Tasks
- **k6 부하 테스트 스크립트**: API 응답 시간, 동시 리포트 생성, 리포트 생성 성능 테스트
- **부하 테스트 CI 구성**: GitHub Actions를 통한 자동화된 부하 테스트
- **p95 기준 설정**: 각 메트릭별 p95, p99 목표값 정의
- **APM 지표 정의**: 응답 시간, 처리량, 에러율, 리포트 생성 지표

### 6.2 Security Tasks
- **OAuth2 Scopes**: 읽기/쓰기 권한별 스코프 정의
- **RBAC**: 역할 기반 접근 제어 (MVP: 단일 관리자 역할)
- **TLS 1.2+**: TLS 설정 및 검증 스크립트
- **감사 로그 스키마**: 모든 주요 이벤트 로깅 구조
- **취약점 스캔**: npm audit, Snyk, TLS 검증

### 6.3 Monitoring Tasks
- **CloudWatch/Prometheus Alerts**: 주요 메트릭별 알림 설정
- **로그 포맷 규칙**: 구조화된 JSON 로그 포맷
- **SLA 지표**: 시스템 가동률, API 응답 시간, 리포트 생성 성능 등

### 6.4 운영 지침서
- **장애 대응 절차**: 장애 등급별 대응 절차 및 체크리스트
- **백업 정책**: Firestore, Storage 백업 전략 및 복원 절차
- **배포/릴리즈 전략**: 환경별 배포 파이프라인 및 릴리즈 체크리스트

---

**작성자**: DevOps & QA 리드  
**검토일**: 2025-01-27  
**버전**: 1.0.0

