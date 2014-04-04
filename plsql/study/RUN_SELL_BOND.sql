DECLARE
  T_EVENT_INFO PKG_EIR_TKP_S.EVENT_INFO_TYPE; -- EVENT INFO
  T_EIR_C PKG_EIR_TKP_S.EIR_CALC_INFO; -- EIR CALC INFO
BEGIN
  -- EVENT INFO
  T_EVENT_INFO.BOND_CODE := 'KR01TKPARK'; -- Bond Code(채권잔고의 PK)
  T_EVENT_INFO.BUY_DATE := '20121130'; -- Buy Date (채권잔고의 PK)
  T_EVENT_INFO.EVENT_DATE := '20121210'; -- 이벤트일 (PK)
  T_EVENT_INFO.EVENT_TYPE := '2'; -- Event 종류(PK) : 1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복
  T_EVENT_INFO.SELL_RT := 0.2; -- 매도율
  
  -- EIR CALC INFO
  T_EIR_C.EVENT_DATE := T_EVENT_INFO.EVENT_DATE; -- EVENT 발생일 (기준일)
  T_EIR_C.BOND_TYPE := '3'; -- 채권종류(1.이표채, 2.할인채, 3.단리채(만기일시), 4.복리채)
  T_EIR_C.ISSUE_DATE := '20121120'; -- 발행일
  T_EIR_C.EXPIRE_DATE := '20141120'; -- 만기일

  
  -- 채권 분할 매도
  PKG_EIR_TKP_S.PR_SELL_BOND(T_EVENT_INFO, T_EIR_C);
  
END;