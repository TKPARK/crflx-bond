DECLARE
  T_BUY_INFO   SELL_INFO_TYPE_S;   -- INPUT
  T_BOND_TRADE BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- SELL INFO
  SELL_INFO_TYPE_S := NEW SELL_INFO_TYPE_S(
                                  , '20121130'  -- 영업일자(잔고 PK)
                                  , 'BOND'      -- 펀드코드(잔고 PK)
                                  , 'KR_단리채' -- 종목코드(잔고 PK)
                                  , '20131130'  -- 매수일자(잔고 PK)
                                  , 10623       -- 매수단가(잔고 PK)
                                  , 1           -- 잔고일련번호(잔고 PK)
                                  , 10400       -- 매도단가
                                  , 20000       -- 매도수량
                                  , '1'         -- 결제일구분(1.당일, 2.익일)
                                  );
  
  -- 채권 매도
  PR_SELL_BOND(T_BUY_INFO, T_BOND_TRADE);
    
END;