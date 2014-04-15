DECLARE
  T_BUY_INFO   BUY_INFO_TYPE_S;    -- INPUT
  T_BOND_TRADE BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- BUY INFO
  T_BUY_INFO := NEW BUY_INFO_TYPE_S('20121130'   -- 거래일자
                                  , 'BOND'       -- 펀드코드
                                  , 'KR_단리채'  -- 종목코드
                                  , 10623        -- 매수단가
                                  , 100000       -- 매수수량
                                  , 0.108        -- 표면이자율
                                  , '1'          -- 결제일구분(1.당일, 2.익일)
                                  );
  
  -- 채권 매수
  PR_BUY_BOND(T_BUY_INFO, T_BOND_TRADE);
    
END;