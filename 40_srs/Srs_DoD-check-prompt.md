# PRD → SRS Definition of Done 체크 프롬프트 (URBAN REPEATERS 전용)

@files(40_srs/01_SRS_urban-repeaters.md)

당신은 ISO/IEC/IEEE 29148:2018 기반 SRS를 리뷰하는 Senior Requirements Engineer입니다.
지금부터 @files 로 첨부한 **URBAN REPEATERS 프로젝트의 SRS**가
아래 Definition of Done(DoD)을 충족하는지 점검하고, 빠진 부분을 보완 제안하는 것이 임무입니다.

========================================
## 1. 이 SRS에 적용할 Definition of Done

아래 항목이 모두 충족되면 SRS v1.0은 “완료(Complete)”로 간주합니다.

1) **PRD 내용 100% 반영 여부**
   - PRD에 있는 기능/스토리/AC/KPI가 SRS에 *어떤 형태로든* 반영되어 있어야 함.
   - 특히:
     - 기능 모듈(F1, F2, F3, …)
     - 사용자 스토리 + Acceptance Criteria
     - KPI/性能(응답시간, 가용성 등)
     - 주요 Pain & JTBD
   - 누락된 항목이 있으면 무엇이 빠졌는지 명시해야 함.

2) **Functional Requirements (REQ-FUNC-xxx)의 atomic성**
   - 모든 기능 요구사항은 REQ-FUNC-xxx 형식의 ID를 가짐.
   - 하나의 REQ-FUNC는 **단일 행동/결과**만 정의해야 함.
   - 각 REQ-FUNC에는 최소한 아래 정보가 있어야 함:
     - Title
     - Source (어떤 Story/F기능/PRD 섹션에서 왔는지)
     - Priority (Must/Should/Could/Won’t – MSCW)
     - Acceptance Criteria (요약 가능, 전체 Given/When/Then는 별도여도 OK)
   - “두 개 이상 기능이 한 문장에 섞여 있는” 경우는 FAIL.

3) **Non-Functional Requirements (REQ-NF-xxx) 완비 여부**
   - 모든 KPI/품질 지표가 REQ-NF-xxx 형태의 항목으로 표현되어야 함.
   - 포함해야 할 영역(해당 프로젝트에 맞는 수준):
     - 성능 (예: p95 응답시간, 처리량)
     - 가용성/신뢰성 (SLA, RPO, RTO)
     - 보안 (TLS, 인증/인가, 로그 보관)
     - 확장성/유지보수성
     - 운영/비용 관련 지표(있다면)
   - 각각은 숫자 기반으로 **테스트 가능**해야 함.

4) **System Context, API, Data Model, Sequence Diagram**
   - System Context & Interfaces:
     - 외부 시스템, 클라이언트, 내부 서비스 관계가 3장에 정리되어 있어야 함.
   - API Endpoint List (Appendix 6.1):
     - 최소한: Method, Path, 주요 Request/Response 필드, 역할
   - Entity & Data Model (Appendix 6.2):
     - 주요 엔터티(예: Report, Branch, Metric, AlertRule 등)와 필드 구조
   - Sequence Diagram (3.4 + 6.3):
     - 핵심 시나리오 1~2개 이상 (예: 보고서 생성, 알림 발송 등)
     - Mermaid 형식으로 작성되었는지 확인.

5) **Traceability Matrix**
   - Story / Feature / Requirement ID / (Test Case ID placeholder) 를 잇는 표가 5장에 존재해야 함.
   - 최소한:
     - Story ID 또는 PRD 섹션
     - REQ-FUNC-xxx / REQ-NF-xxx
   - 테스트 ID는 placeholder여도 괜찮지만, **열 구조**는 준비되어 있어야 함.

6) **ISO 29148 기본 구조 준수 여부**
   - 1~6장 전체가 아래 구조를 가지고 있어야 함:
     - 1. Introduction (Purpose, Scope, Definitions, References)
     - 2. Stakeholders
     - 3. System Context and Interfaces
     - 4. Specific Requirements (4.1 Functional, 4.2 NFR)
     - 5. Traceability Matrix
     - 6. Appendix (API / Data Model / Sequence Diagrams 등)

7) **요구사항 문장 자체의 테스트 가능성**
   - “빠르게, 원활하게, 충분히, 적절히” 등 모호한 표현이 없어야 함.
   - 각 요구사항은 **측정 가능**하거나, Yes/No로 판별 가능한 형태여야 함.

8) **Scope / Assumptions / Constraints / References**
   - In-Scope / Out-of-Scope가 1.2 Scope에 명시되어야 함.
   - Assumptions & Constraints 안에:
     - 기술 스택 제약(언어/프레임워크/LLM 호출 방식 등)
     - 운영 상의 가정이 포함되어야 함.
   - References에 PRD / VPS / JTBD / Market 분석 문서를 ID와 함께 나열해야 함.

========================================
## 2. 작업 지시

### 2-1. 1차: DoD 항목별 PASS/FAIL 진단표

1. @files 로 제공된 SRS 전체를 검토합니다.
2. 위 DoD 1)~8) 항목별로 아래 형태의 표를 만드세요.

| DoD ID | 항목 설명 | Status (PASS/FAIL/PARTIAL) | 근거 SRS 위치(섹션/ID 예시) | 보완 필요 시 수정 방향 요약 |
|--------|-----------|---------------------------|-----------------------------|------------------------------|

- **PASS**: 현재 SRS가 큰 수정 없이 조건을 만족하는 경우
- **PARTIAL**: 부분적으로만 충족, 일부 보완이 필요한 경우
- **FAIL**: 거의 비어 있거나, 구조적으로 빠져 있는 경우

### 2-2. 2차: 수정 제안(패치 플랜)

3. PARTIAL 또는 FAIL인 항목에 대해서는,
   아래 형식으로 **구체적인 패치 제안**을 작성하세요.

- 어느 섹션을 추가/수정해야 하는지 (예: 4.1 Functional Requirements, REQ-FUNC-0xx 추가)
- 새로 만들어야 할 REQ-FUNC / REQ-NF의 예시 1~3개
- 추가해야 할 표/다이어그램의 제목과 간단한 내용 요약

형식 예시:

- DoD-3 (NFR 부족) 보완 제안
  - [추가] REQ-NF-003: 보고서 생성 응답시간 p95 ≤ 5s, 검증방법: 부하테스트
  - [추가] REQ-NF-004: SLA ≥ 99.5%, RPO ≤ 1h …

### 2-3. 3차: 바로 붙여넣을 수 있는 초안 코드 블록

4. 가능하다면, **SRS에 바로 붙여넣을 수 있는 초안**을
   ```markdown``` 코드블록으로 제공하세요.

- 예: 새로 추가해야 할 REQ-NF 테이블 행, Traceability Matrix 행, Sequence Diagram(Mermaid) 등
- 이미 존재하는 내용을 크게 바꾸지 말고, “추가/보완” 위주로 제안하세요.

========================================
## 3. 출력 형식

1. 먼저 DoD 진단표를 한 번에 보여줍니다.
2. 이어서, PARTIAL/FAIL 항목별로 보완 제안을 섹션별로 정리합니다.
3. 마지막으로, “바로 복사해서 SRS에 붙일 수 있는” 초안들을 코드 블록으로 제공합니다.

이제 @files 로 제공된 SRS를 기준으로 위 작업을 수행하고,
결과를 출력하세요.
