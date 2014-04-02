CREATE OR REPLACE PACKAGE PKG_EIR_NESTED_S AS
  -- EIR Calculation Information Type
  TYPE EIR_CALC_INFO IS RECORD (
    EVENT_DATE     CHAR(8)       -- EVENT 발생일 (기준일)
   ,BOND_TYPE      CHAR(1)       -- 채권종류(1.이표채, 2.할인채, 3.단리채(만기일시), 4.복리채)
   ,ISSUE_DATE     CHAR(8)       -- 발행일
   ,EXPIRE_DATE    CHAR(8)       -- 만기일
   ,FACE_AMT       NUMBER(20,2)  -- 액면금액
   ,BOOK_AMT       NUMBER(20,2)  -- 장부금액
   ,IR             NUMBER(10,5)  -- 표면이자율
   ,EIR            NUMBER(15,10) -- 유효이자율
   ,INT_CYCLE      NUMBER(10)    -- 이자주기(월)
   ,ALLOWED_LIMIT  NUMBER(10,5)  -- 오차한도($)
  );
  -- EVENT INFO TYPE
  TYPE EVENT_INFO_TYPE IS RECORD (
    BOND_CODE      CHAR(10)      -- Bond Code(채권잔고의 PK)
   ,BUY_DATE       CHAR(8)       -- Buy Date (채권잔고의 PK)
   ,EVENT_DATE     CHAR(8)       -- 이벤트일 (PK)
   ,EVENT_TYPE     CHAR(1)       -- Event 종류(PK) : 1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복
   ,IR             NUMBER(10,5)  -- 표면이자율
   ,EIR            NUMBER(15,10) -- 유효이자율
   ,SELL_RT        NUMBER(10,5)  -- 매도율
   ,FACE_AMT       NUMBER(20,2)  -- 액면금액
   ,BOOK_AMT       NUMBER(20,2)  -- 장부금액
  );
  
  -- 외부에 노출할 Function, Procedure만 선언부에 선언
  -- 최초 매수 EVENT 반영 (IN : Event Info, OUT : EVENT_RESULT Class)
  PROCEDURE PR_APPLY_NEW_BUY_EVENT(I_EV_INFO IN EVENT_INFO_TYPE, O_EV_RET IN OUT EVENT_RESULT_NESTED_S%ROWTYPE);
  
  -- 추가 Event 반영 Procedure (IN : Event Info, OUT : EVENT_RESULT Class)
  PROCEDURE PR_APPLY_ADDTIONAL_EVENT(I_EV_INFO IN EVENT_INFO_TYPE, O_EV_RET IN OUT EVENT_RESULT_NESTED_S%ROWTYPE);
  
  --외부로 노출할 함수와 FUNCTION만 선언부에 선언함. 아래 함수와 PROC는 내부에서만 사용하므로 선언부에서 제외 <NOT_DEF> 나중에 Comment 처리
  -- <TEST_RESULT> 노출을 위해 선언부를 Comment처리하면 FN_GET_EIR_CALC_INFO' not declared in this scope 와 같이 컴파일시 오류발생
  -- 이유는 해당 Function을 Call하는 Proc의 Scope 내에 이 함수가 선언되어야 하므로,
  -- 따라서, 공용함수이므로 노출이 되더라도 선언부를 Comment 처리하지 않는다.
  -- Functions
  -- Create Cash Flows
  FUNCTION FN_CREATE_CASH_FLOWS (I_EIR_C EIR_CALC_INFO) RETURN TABLE_CF_S;
  -- Simulate EIR (최초 EIR 찾기) -> I_EIR_C에 필드값을 설정할 수 없으므로 O_EIR OUT 추가함.
  FUNCTION FN_SIMULATE_EIR(I_EIR_C EIR_CALC_INFO, O_EIR OUT NUMBER) RETURN TABLE_CF_S;
  -- Create SangGak Flows (상각FLOWS 생성)
  FUNCTION FN_CREATE_SANGGAK_FLOWS(I_EIR_C EIR_CALC_INFO, I_CF_LIST TABLE_CF_S) RETURN TABLE_SGF_S;
  -- CalcDays Function
  FUNCTION FN_CALC_DAYS(I_FR_DATE CHAR, I_TO_DATE CHAR) RETURN NUMBER;
  -- Round Number(일단 소수 2자리까지 TRUNC 기준) -- 금액기준 통일
  FUNCTION FN_ROUND(I_NUM NUMBER) RETURN NUMBER;
  -- Calculate Total Compound Interest (복리채 총이자계산) 발행일 ~ 만기일
  FUNCTION FN_CALC_TOT_INT_OF_COMPOUND(I_EIR_C EIR_CALC_INFO) RETURN NUMBER;
  -- Calculate Compound Interest (복리채 이자계산) 발행일 ~ 기준일까지
  FUNCTION FN_CALC_INT_OF_COMPOUND(I_EIR_C EIR_CALC_INFO, I_BASE_DATE CHAR) RETURN NUMBER;
  -- Calculate Accrued Interest (경과이자 계산) 발행일 ~ 기준일까지
  FUNCTION FN_CALC_ACCRUED_INT(I_EIR_C EIR_CALC_INFO) RETURN NUMBER;
  -- Get Just Before Int Date (직전이자지급일,YYYYMMDD)
  FUNCTION FN_GET_BF_INT_DATE(I_EIR_C EIR_CALC_INFO) RETURN CHAR;
  
  -- 해당Event정보로 해당잔고의 마지막 Event 정보 Load (DB에서 데이타를 읽어서 마지막 EVENT_RESULT를 Load한다.
  FUNCTION FN_GET_LAST_EVELT_RESULT(I_EV_INFO EVENT_INFO_TYPE) RETURN EVENT_RESULT_NESTED_S%ROWTYPE;
  -- 해당Event정보로 EIR_CALC_INFO GET
  FUNCTION FN_GET_EIR_CALC_INFO(I_EV_INFO EVENT_INFO_TYPE) RETURN EIR_CALC_INFO;
    
  -- Calculate Current Value
  -- I_EIR(유효이자율), O_CF_LIST(Cash Flow Collection, 필드값 변경 IN OUT), O_VALUE_SUM(현재가치의합)
  PROCEDURE PR_CALC_CUR_VALUE(I_EIR IN NUMBER, O_CF_LIST IN OUT TABLE_CF_S, O_VALUE_SUM IN OUT NUMBER);
  -- Find Approximate EIR (근사 유효이자 구하기) 
  -- BookAmt(장부금액), DifLimit(오차한도), I_UNIT(가감할 소수자리), I_START_EIR(시작 EIR) , O_SAME_YN(현재가치합과 장부금액의 일치여부)
  -- Trial And Error 방식으로 근사 EIR 구하기, Function으로는 Collection의 필드값 변경불가 , 프로시저로 처리함.
  PROCEDURE PR_FIND_APPROXIMATE_EIR(I_BOOK_AMT IN NUMBER, I_DIF_LIMIT IN NUMBER, I_UNIT IN NUMBER, I_START_EIR IN NUMBER, O_CF_LIST IN OUT TABLE_CF_S, O_SAME_YN IN OUT CHAR, O_APPROX_EIR IN OUT NUMBER);
  
  -- Cash Flow, SangGak Flow 초기화 프로시저
  PROCEDURE PR_INIT_CF (O_CF  IN OUT CF_TYPE_S);
  PROCEDURE PR_INIT_SGF(O_SGF IN OUT SGF_TYPE_S);
  
  -- Sort SangGak Flow List (기준일기준 ASC) Bubble Sort 기준
  PROCEDURE PR_SORT_SANGGAK_FLOWS(O_SGF_LIST IN OUT TABLE_SGF_S);
  
  --<EVENT_SEQ> EVENT_RESULT_NESTED_S에서 동일 EVENT일의 MAX + 1 SEQ GET
  FUNCTION FN_GET_EVENT_SEQ(I_EV_INFO EVENT_INFO_TYPE) RETURN NUMBER;
  -- <EVENT_SEQ> 기존 SGF_LIST 동일 EVENT일의 상각스케쥴 SEQ GET
  FUNCTION FN_GET_SGF_SEQ(I_BASE_DATE CHAR, I_SGF_LIST TABLE_SGF_S) RETURN NUMBER;
  
  -- 객체 STRING 함수
  FUNCTION FN_GET_EVENT_RESULT_NESTED_STR(I_EV_RET EVENT_RESULT_NESTED_S%ROWTYPE) RETURN VARCHAR2;
  FUNCTION FN_GET_CASH_FLOW_STR(I_CF CF_TYPE_S) RETURN VARCHAR2;
  FUNCTION FN_GET_SANGGAK_FLOW_STR(I_SGF SGF_TYPE_S) RETURN VARCHAR2;
  
  -- 30/360 기준 일수 계산
  FUNCTION FN_CALC_DAYS_30360(I_FR_DATE CHAR, I_TO_DATE CHAR) RETURN NUMBER;
  
END PKG_EIR_NESTED_S;
/