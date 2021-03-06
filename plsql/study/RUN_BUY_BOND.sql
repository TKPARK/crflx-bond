DECLARE
  T_EVENT_INFO PKG_EIR_TKP_S.EVENT_INFO_TYPE; -- EVENT INFO
  T_EIR_C PKG_EIR_TKP_S.EIR_CALC_INFO; -- EIR CALC INFO
BEGIN
  -- EVENT INFO
  T_EVENT_INFO.BOND_CODE := '5이표_50년'; -- Bond Code(채권잔고의 PK)
  T_EVENT_INFO.BUY_DATE := '20130515'; -- Buy Date (채권잔고의 PK)
  T_EVENT_INFO.EVENT_DATE := '20130516'; -- 이벤트일 (PK)
  T_EVENT_INFO.EVENT_TYPE := '1'; -- Event 종류(PK) : 1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복
  T_EVENT_INFO.IR := 0.108; -- 표면이자율
  T_EVENT_INFO.FACE_AMT := 100000000; -- 액면금액
  T_EVENT_INFO.BOOK_AMT := 100992740; -- 장부금액

  -- EIR CALC INFO
  T_EIR_C.EVENT_DATE := T_EVENT_INFO.EVENT_DATE; -- EVENT 발생일 (기준일)
  T_EIR_C.BOND_TYPE := '1'; -- 채권종류(1.이표채, 2.할인채, 3.단리채(만기일시), 4.복리채)
  T_EIR_C.ISSUE_DATE := '20121120'; -- 발행일
  T_EIR_C.EXPIRE_DATE := '20621120'; -- 만기일
  T_EIR_C.FACE_AMT := T_EVENT_INFO.FACE_AMT; -- 액면금액
  T_EIR_C.BOOK_AMT := T_EVENT_INFO.BOOK_AMT; -- 장부금액
  T_EIR_C.IR := T_EVENT_INFO.IR; -- 표면이자율
  T_EIR_C.INT_CYCLE := 6; -- 이자주기(월)
  
  -- 채권 신규 매수
  PKG_EIR_TKP_S.PR_NEW_BUY_BOND(T_EVENT_INFO, T_EIR_C);
    
END;