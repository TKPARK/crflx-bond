DECLARE
  T_SELL_INFO  SELL_INFO_TYPE;     -- INPUT
  T_BOND_TRADE BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- SELL INFO
  T_SELL_INFO := NEW SELL_INFO_TYPE('20121130'   -- �ŷ�����(�ܰ� PK)
                                  , 'TEST_0424C'  -- �ݵ��ڵ�(�ܰ� PK)
                                  , 'KR_�ܸ�ä2' -- �����ڵ�(�ܰ� PK)
                                  , '20121130'   -- �ż�����(�ܰ� PK)
                                  , 10623        -- �ż��ܰ�(�ܰ� PK)
                                  , 1            -- �ܰ��Ϸù�ȣ(�ܰ� PK)
                                  , 10400        -- �ŵ��ܰ�
                                  , 20000        -- �ŵ�����
                                  , 0.108        -- ǥ��������
                                  , '1'          -- �����ϱ���(1.����, 2.����)
                                  );
  
  -- �ܰ� ����
  PR_ADD_BALANCE(T_SELL_INFO, T_BOND_TRADE);
    
END;