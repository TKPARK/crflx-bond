DECLARE
  T_SELL_INFO  SELL_INFO_TYPE;     -- INPUT
  T_BOND_TRADE BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- SELL INFO
  T_SELL_INFO := NEW SELL_INFO_TYPE('20121120'  -- 거래일자(잔고 PK)
                                  , 'TEST_0428' -- 펀드코드(잔고 PK)
                                  , 'KR_이표채' -- 종목코드(잔고 PK)
                                  , '20121120'  -- 매수일자(잔고 PK)
                                  , 10623       -- 매수단가(잔고 PK)
                                  , 1           -- 잔고일련번호(잔고 PK)
                                  , 0           -- 매도단가
                                  , 0           -- 매도수량
                                  , 0           -- 표면이자율
                                  , ''          -- 결제일구분(1.당일, 2.익일)
                                  );
  
  -- 잔고 생성
  PR_ADD_BALANCE(T_SELL_INFO, '20130520', T_BOND_TRADE);
    
END;