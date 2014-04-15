DECLARE
  T_BUY_INFO   SELL_INFO_TYPE_S;   -- INPUT
  T_BOND_TRADE BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- SELL INFO
  SELL_INFO_TYPE_S := NEW SELL_INFO_TYPE_S(
                                  , '20121130'  -- ��������(�ܰ� PK)
                                  , 'BOND'      -- �ݵ��ڵ�(�ܰ� PK)
                                  , 'KR_�ܸ�ä' -- �����ڵ�(�ܰ� PK)
                                  , '20131130'  -- �ż�����(�ܰ� PK)
                                  , 10623       -- �ż��ܰ�(�ܰ� PK)
                                  , 1           -- �ܰ��Ϸù�ȣ(�ܰ� PK)
                                  , 10400       -- �ŵ��ܰ�
                                  , 20000       -- �ŵ�����
                                  , '1'         -- �����ϱ���(1.����, 2.����)
                                  );
  
  -- ä�� �ŵ�
  PR_SELL_BOND(T_BUY_INFO, T_BOND_TRADE);
    
END;