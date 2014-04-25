DECLARE
  T_CANCEL_INFO  CANCEL_INFO_TYPE;   -- INPUT
  T_BOND_TRADE   BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- CANCEL INFO
  T_CANCEL_INFO := NEW CANCEL_INFO_TYPE('20140424' -- 거래일자(PK)
                                      , 5          -- 거래일련번호(PK)
                                      );
  
  -- 취소
  PR_CANCEL_BOND(T_CANCEL_INFO, T_BOND_TRADE);
    
END;