DECLARE
  T_SELL_INFO  SELL_INFO_TYPE;     -- INPUT
  T_BOND_TRADE BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- SELL INFO
  T_SELL_INFO := NEW SELL_INFO_TYPE('20130516'  -- 거래일자(잔고 PK)
                                  , 'KR_FUND'   -- 펀드코드(잔고 PK)
                                  , 'KR_단리채' -- 종목코드(잔고 PK)
                                  , '20130516'  -- 매수일자(잔고 PK)
                                  , 10623       -- 매수단가(잔고 PK)
                                  , 1           -- 잔고일련번호(잔고 PK)
                                  , 10400       -- 매도단가
                                  , 20000       -- 매도수량
                                  , '1'         -- 결제일구분(1.당일, 2.익일)
                                  );
  
  -- 채권 매도
  PR_SELL_BOND(T_SELL_INFO, T_BOND_TRADE);
    
END;