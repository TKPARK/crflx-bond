DECLARE
  T_CANCEL_INFO  CANCEL_INFO_TYPE;   -- INPUT
  T_BOND_TRADE   BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- CANCEL INFO
  T_CANCEL_INFO := NEW CANCEL_INFO_TYPE('20130516' -- �ŷ�����(PK)
                                      , 1          -- �ŷ��Ϸù�ȣ(PK)
                                      );
  
  -- ���
  PR_CANCEL_BOND(T_CANCEL_INFO, T_BOND_TRADE);
    
END;