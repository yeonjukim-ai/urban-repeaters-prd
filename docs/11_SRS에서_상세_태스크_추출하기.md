11_SRS에서_상세_태스크_추출하기.md

(연주 개인 프로젝트용 / Cursor 컨텍스트 최적화 버전)

📌 문서 목적(Purpose)

이 문서는 SRS(Software Requirements Specification) 문서를 기반으로
개발 실행이 가능한 Epic / Story / Task 형태로 분해하기 위한 작업 지식(Working Knowledge)을 정리한 것이다.

Cursor, GPT-0.1, Gemini 등의 에이전트에게 일관된 기준으로 태스크를 생성하도록 하기 위해
본 문서를 context로 제공한다.

1. SRS → Task 변환 시 지켜야 할 기본 원칙
1) 요구사항 1개 = 태스크 1개가 아니다

요구사항은 일반적으로 여러 기능 요소가 뭉쳐 있는 큰 단위(Feature)

실제 개발에서는 여러 개의 Epic → Story → Task로 분해되어야 한다.

예:

“강의 검색 기능 제공”
→ 검색 UI / 검색 API / DB 인덱싱 / 예외처리 / 화면 상태관리 등 여러 Task로 분리됨

2) 태스크는 ‘레시피’처럼 구체적이어야 한다

“어떤 결과물을 만들고”

“어떤 조건이 충족되면 완료인지(AC)”

“어떤 선행 작업이 필요한지”

“어떤 기술 스택으로 구현해야 하는지”
를 모두 명확하게 해야 한다.

3) 태스크 간 선후 관계 명확화

Task는 독립적으로 실행될 수도 있지만, 대부분 **의존성(Dependency)**이 존재한다.

따라서 에이전트에게 태스크를 만들게 할 때도 반드시:

선행 태스크

후행 태스크

병렬 가능 태스크
를 표시해야 한다.

4) 태스크는 가능한 작은 단위로 쪼갤수록 좋다

“한 번에 코드 생성”이 가능할 정도로 작은 단위

API 하나 / UI 하나 / 상태 하나 / DB 마이그레이션 하나 등

2. 태스크 템플릿(Task Template)

Cursor나 GPT가 태스크를 생성할 때, 반드시 아래 구조를 지키도록 한다.

🟦 Task Template (기본)
- Task ID:
- Task Name:
- Epic:
- Description:
- Acceptance Criteria (AC):
- Type: (frontend / backend / api / db / ui / integration / test / ops 등)
- Dependencies:
- Output:

🟩 예시
Task ID: T-API-01
Task Name: 로그인 API 구현

Epic: E1 - 사용자 인증

Description:
- Supabase Auth를 기반으로 이메일/비밀번호 로그인 API를 구현한다.
- 성공 시 세션 토큰 반환, 실패 시 에러코드 처리.

Acceptance Criteria:
- 정상 로그인 시 세션 토큰 발급
- 잘못된 credential 입력 시 명확한 오류 전달
- DB 쿼리 및 유효성 검사 포함

Type: backend/api

Dependencies:
- DB 스키마 설계 완료 (T-DB-01)

Output:
- /api/login endpoint

3. 태스크 분해 기준(Task Breakdown Rules)
① API 기준(Task)로 분리할 때

API 하나 = 하나의 Task 로 본다.

항목 예:

Endpoint 생성

Request/Response 스키마 정의

Validation

Error Handling

Controller / Service / Repository 구성 (프레임워크 의존)

② DB 기준(Task)로 분리할 때

DB 관련 작업도 각각 분해된다.

항목 예:

Table 생성

Column 추가

Index 생성

Foreign key 설정

Supabase SQL Migration 작성

초기 Seed 데이터 삽입

각각 Task로 나눌 수 있다.

③ Frontend(UI) 기준 분리

화면 하나라고 태스크 하나가 아니다.

항목 예:

화면 레이아웃 구성

로딩/에러 상태 처리

API 연동 로직 구현

상태관리(store) 생성

필터/검색 UI 구현

컴포넌트 단위 분리

④ 비기능 요구사항(NFR) 분해

로드 테스트(부하 테스트)

보안 점검

에러 로깅/모니터링 설정

성능 최적화

운영 자동화

이런 건 **OPS(Task)**로 분리한다.

4. SRS → Task 변환 절차(6단계)
Step 1. SRS 전체 구조 파악

기능 요구사항(FR)

비기능 요구사항(NFR)

시스템 아키텍처

기술 스택

을 하나의 “큰 지도”로 파악한다.

Step 2. 요구사항을 Epic 단위로 그룹핑

Epic 예시:

E1 사용자 인증

E2 강의 검색

E3 강의 상세 화면

E4 결제

E5 관리자 페이지

Step 3. 각 Epic을 Story / 기능단위로 나누기

예:

로그인

회원가입

비밀번호 재설정

Step 4. Story를 Task로 쪼개기

각 Story는 실제 실행 가능한 여러 Task로 나눌 수 있다.

Step 5. 각 Task에 DOD(완료 정의)와 Dependencies 추가

Acceptance Criteria가 명확해야 에이전트가 작업 가능

Dependency가 명확해야 순서 자동 정렬 가능

Step 6. 전체 태스크 의존성 그래프 생성

어떤 것을 먼저 구현해야 하는지 흐름을 보여줌

에이전트 병렬 작업 가능하게 만드는 핵심 요소

예:

T-DB-01 → T-API-01 → T-FE-01

5. 태스크 구조 시각화 예시(Task Tree Example)
E1 사용자 인증
 ├─ S1 로그인 기능
 │    ├─ T-DB-01 유저 테이블 생성
 │    ├─ T-API-01 로그인 API
 │    └─ T-FE-01 로그인 화면 UI
 ├─ S2 회원가입 기능
 │    ├─ T-DB-02 필드 추가
 │    ├─ T-API-02 회원가입 API
 │    └─ T-FE-02 회원가입 UI
 └─ S3 인증 세션 유지
      ├─ T-API-03 토큰 재발급
      └─ T-FE-03 세션 유지 로직

6. MVP 관점에서 태스크를 조정하는 기준

반드시 필요

더미 UI로 대체 가능

API 없이 로컬 JSON으로 대체 가능

2차 버전으로 미뤄도 되는 작업

이 기준으로 태스크 우선순위를 정리한다.
이 작업은 SRS v3 → 태스크 변환 후 반드시 한 번 더 수행해야 한다.

7. 이 문서를 Cursor에 제공할 때의 목적

태스크 추출 결과의 품질이 일관적으로 유지된다.

모델이 “교수님/강사님이 말한 방식” 그대로 태스크를 구성하게 된다.

Epic/Task/Dependency 생성이 안정된다.

이후 Agentic Coding 시 코드 품질이 크게 향상된다.

8. 출력 형식 규칙

에이전트에게 태스크를 만들게 할 때는 아래 형식을 강제한다.

[Epic List]

[Epic E1]
- Epic 설명
- Story 목록

[Task List]
- Task ID:
- Task Name:
- Epic:
- Description:
- AC:
- Type:
- Dependencies:
- Output:

📌 이 문서는 연주의 프로젝트에서 필수 context 문서임

태스크 생성 프롬프트, Plan 생성, Agentic Coding 단계에서 반드시 함께 넣어야 하는 파일이다.