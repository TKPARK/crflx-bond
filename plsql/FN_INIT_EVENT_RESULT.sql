CREATE OR REPLACE FUNCTION ISS.FN_INIT_EVENT_RESULT
  RETURN EVENT_RESULT_NESTED_S%ROWTYPE AS
  T_EVENT_RESULT EVENT_RESULT_NESTED_S%ROWTYPE;
BEGIN
  T_EVENT_RESULT.FUND_CODE      := ''; -- 펀드코드
  T_EVENT_RESULT.BOND_CODE      := ''; -- 종목코드
  T_EVENT_RESULT.BUY_DATE       := ''; -- 매수일자
  T_EVENT_RESULT.BUY_PRICE      := 0;  -- 매수단가
  T_EVENT_RESULT.BALAN_SEQ      := 0;  -- 잔고일련번호
  T_EVENT_RESULT.EVENT_DATE     := ''; -- 이벤트일 (PK)
  T_EVENT_RESULT.EVENT_SEQ      := 0;  -- 이벤트 SEQ (PK : 동일한 EVENT일에 2개이상의 동일한 EVENT 발생시를 고려함)
  T_EVENT_RESULT.EVENT_TYPE     := ''; -- Event 종류(1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복)
  T_EVENT_RESULT.IR             := 0;  -- 표면이자율
  T_EVENT_RESULT.EIR            := 0;  -- 유효이자율
  T_EVENT_RESULT.SELL_RT        := 0;  -- 매도율
  T_EVENT_RESULT.TOT_INT        := 0;  -- 총이자금액
  T_EVENT_RESULT.ACCRUED_INT    := 0;  -- 경과이자
  T_EVENT_RESULT.SANGGAK_AMT    := 0;  -- 상각금액
  T_EVENT_RESULT.MI_SANGGAK_AMT := 0;  -- 미상각금액
  
  RETURN T_EVENT_RESULT;
END;