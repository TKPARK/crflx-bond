CREATE OR REPLACE PACKAGE ISS.PKG_EIR_TKP_S AS
  -- EIR Calculation Information Type
  TYPE EIR_CALC_INFO IS RECORD (
    EVENT_DATE     CHAR(8)            -- EVENT 발생일 (기준일)
   ,BOND_TYPE      CHAR(1)            -- 채권종류(1.이표채, 2.할인채, 3.단리채(만기일시), 4.복리채)
   ,ISSUE_DATE     CHAR(8)            -- 발행일        
   ,EXPIRE_DATE    CHAR(8)            -- 만기일        
   ,FACE_AMT       NUMBER(20,2)       -- 액면금액      
   ,BOOK_AMT       NUMBER(20,2)       -- 장부금액      
   ,IR             NUMBER(10,5)       -- 표면이자율    
   ,EIR            NUMBER(15,10)      -- 유효이자율    
   ,INT_CYCLE      NUMBER(10)         -- 이자주기(월)  
   ,ALLOWED_LIMIT  NUMBER(10,5)       -- 오차한도($)   
  );
  -- EVENT INFO TYPE
  TYPE EVENT_INFO_TYPE IS RECORD (
    BOND_CODE      CHAR(10)      -- Bond Code(채권잔고의 PK) 
   ,BUY_DATE       CHAR(8)       -- Buy Date (채권잔고의 PK) 
   ,EVENT_DATE     CHAR(8)       -- 이벤트일 (PK) 
   ,EVENT_TYPE     CHAR(1)       -- Event 종류(PK) : 1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복 
   ,IR             NUMBER(10,5)  -- 표면이자율     
   ,EIR            NUMBER(15,10)      -- 유효이자율    
   ,SELL_RT        NUMBER(10,5)       -- 매도율        
   ,FACE_AMT       NUMBER(20,2)       -- 액면금액      
   ,BOOK_AMT       NUMBER(20,2)       -- 장부금액      
  );
  
  -- 채권 신규 매수
  PROCEDURE PR_NEW_BUY_BOND(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO);
  -- 채권 분할 매도
  PROCEDURE PR_SELL_BOND(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO);
  
  
  -- 경과이자 계산
  FUNCTION FN_CALC_ACCRUED_INT(I_EIR_C EIR_CALC_INFO) RETURN NUMBER;
  -- 경과이자 : 할인채(discount debenture)
  FUNCTION FN_GET_DISCNT_ACCRUED_INT(I_EIR_C EIR_CALC_INFO) RETURN NUMBER;
  -- 경과이자 : 이표채(단리)(coupon bond)
  FUNCTION FN_GET_CPN_ACCRUED_INT(I_EIR_C EIR_CALC_INFO) RETURN NUMBER;
  -- 경과이자 : 단리채(만기)(simple interest bond)
  FUNCTION FN_GET_SIMPLE_ACCRUED_INT(I_EIR_C EIR_CALC_INFO) RETURN NUMBER;
  -- 경과이자 : 복리채(compound bond)
  FUNCTION FN_GET_CPND_ACCRUED_INT(I_EIR_C EIR_CALC_INFO) RETURN NUMBER;
  
  -- 이자 계산 : (1.이표채, 2.할인채, 3.단리채(만기일시))
  FUNCTION FN_GET_CAL_INT(BOND_TYPE CHAR, I_DAYS NUMBER, I_FACE_AMT NUMBER, I_IR NUMBER) RETURN NUMBER;
  -- 이자 계산 : (4.복리채)
  FUNCTION FN_GET_CAL_CPND_INT(I_EIR_C EIR_CALC_INFO, I_BF_BASE_DATE CHAR, I_BASE_DATE CHAR) RETURN NUMBER;
  
  
  -- Cash Flow
  FUNCTION FN_CREATE_CASH_FLOWS (I_EIR_C EIR_CALC_INFO) RETURN TABLE_CF_S;
  -- INIT CF_TYPE_S
  FUNCTION FN_INIT_CF_TYPE_S RETURN CF_TYPE_S;
  
  
  -- EIR
  FUNCTION FN_GET_EIR(I_EIR_C EIR_CALC_INFO, I_CF_LIST IN OUT TABLE_CF_S) RETURN NUMBER;
  -- 근사 EIR 찾기
  FUNCTION FN_GET_TRIAL_AND_ERROR(I_EIR_C EIR_CALC_INFO, I_CF_LIST TABLE_CF_S, I_IR NUMBER, I_UNIT NUMBER) RETURN NUMBER;
  
  
  -- 상각 테이블
  FUNCTION FN_GET_SANG_GAK(I_EIR_C EIR_CALC_INFO, I_CF_LIST TABLE_CF_S) RETURN TABLE_SGF_S;
  -- INIT CF_TYPE_S
  FUNCTION FN_INIT_SGF_TYPE_S RETURN SGF_TYPE_S;
  -- QUICK SORT
  PROCEDURE PR_QUICK_SORT(I_SG_LIST IN OUT TABLE_SGF_S, I_LOW IN NUMBER, I_HIGH IN NUMBER);
  PROCEDURE PR_SORT_SANGGAK_FLOWS(O_SGF_LIST IN OUT TABLE_SGF_S);
  
  
  -- 채번(Event 결과정보 EVENT_SEQ)
  FUNCTION FN_GET_EVENT_SEQ(I_EVENT_INFO EVENT_INFO_TYPE) RETURN NUMBER;
  -- INSERT(Event 결과정보)
  PROCEDURE PR_INSERT_EVENT_RESULT_INFO(I_EVENT_INFO EVENT_INFO_TYPE, I_CF_LIST TABLE_CF_S, I_SG_LIST TABLE_SGF_S);
  
  -- 채번(잔고 BALAN_SEQ)
  FUNCTION FN_GET_BALAN_SEQ(I_BOND_BALANCE BOND_BALANCE%ROWTYPE) RETURN NUMBER;
  -- INSERT(잔고)
  PROCEDURE PR_INSERT_BOND_BALANCE(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO, I_ACCRUED_INT NUMBER);
  
  -- 채번(거래내역 TRD_SEQ)
  FUNCTION FN_GET_TRD_SEQ(I_EVENT_INFO EVENT_INFO_TYPE) RETURN NUMBER;
  -- INSERT(거래내역)
  PROCEDURE PR_INSERT_BOND_TRADE(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO, I_ACCRUED_INT NUMBER);
  
  
  -- FROM ~ TO 일수계산
  FUNCTION FN_CALC_DAYS(I_FROM_DATE CHAR, I_TO_DATE CHAR) RETURN NUMBER;
  -- 이자발생횟수 계산
  FUNCTION FN_GET_INT_CNT(I_EIR_C EIR_CALC_INFO) RETURN NUMBER;
  -- 직전이자지급일 계산
  FUNCTION FN_GET_BF_INT_DATE(I_EIR_C EIR_CALC_INFO) RETURN CHAR;
  -- 직후이자지급일 계산
  FUNCTION FN_GET_AF_INT_DATE(I_EIR_C EIR_CALC_INFO) RETURN CHAR;
  -- 금액 절사
  FUNCTION FN_ROUND(I_NUM NUMBER) RETURN NUMBER;
  FUNCTION FN_ROUND(I_NUM NUMBER, I_DIGITS NUMBER) RETURN NUMBER;
  -- 기존 SGF_LIST 동일 EVENT일의 상각스케쥴 SEQ GET
  FUNCTION FN_GET_SGF_SEQ(I_BASE_DATE CHAR, I_SGF_LIST TABLE_SGF_S) RETURN NUMBER;
  
  
  -- 객체 STRING 함수
  FUNCTION FN_GET_EVENT_RESULT_NESTED_STR(I_EV_RET EVENT_RESULT_NESTED_S%ROWTYPE) RETURN VARCHAR2;
  FUNCTION FN_GET_CASH_FLOW_STR(I_CF CF_TYPE_S) RETURN VARCHAR2;
  FUNCTION FN_GET_SANGGAK_FLOW_STR(I_SGF SGF_TYPE_S) RETURN VARCHAR2;
  
  
  
END PKG_EIR_TKP_S;