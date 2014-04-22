DECLARE
  T_SELL_INFO  SELL_INFO_TYPE;     -- INPUT
  T_BOND_TRADE BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- SELL INFO
  T_SELL_INFO := NEW SELL_INFO_TYPE('20130516'  -- �ŷ�����(�ܰ� PK)
                                  , 'TEST_TK'   -- �ݵ��ڵ�(�ܰ� PK)
                                  , 'KR_�ܸ�ä' -- �����ڵ�(�ܰ� PK)
                                  , '20130516'  -- �ż�����(�ܰ� PK)
                                  , 10623       -- �ż��ܰ�(�ܰ� PK)
                                  , 1           -- �ܰ��Ϸù�ȣ(�ܰ� PK)
                                  );
  
  -- �ܰ� �߰�
  PR_ADD_BALANCE(T_SELL_INFO, T_BOND_TRADE);
    
END;