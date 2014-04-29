DECLARE
  T_CHANGE_INFO  CHANGE_BOND_IR_INFO_TYPE; -- INPUT
  T_BOND_TRADE   BOND_TRADE%ROWTYPE;       -- OUTPUT
BEGIN
  -- CHANGE INFO
  T_CHANGE_INFO := NEW CHANGE_BOND_IR_INFO_TYPE('20130520'  -- 거래일자(잔고 PK)
                                              , 'TEST_0428' -- 펀드코드(잔고 PK)
                                              , 'KR_이표채' -- 종목코드(잔고 PK)
                                              , '20121120'  -- 매수일자(잔고 PK)
                                              , 10623       -- 매수단가(잔고 PK)
                                              , 1           -- 잔고일련번호(잔고 PK)
                                              , 0.106       -- 표면이자율
                                              );
  
  -- 이자율 변경
  PR_CHANGE_BOND_IR(T_CHANGE_INFO, T_BOND_TRADE);
    
END;