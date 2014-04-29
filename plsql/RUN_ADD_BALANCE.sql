DECLARE
  T_SELL_INFO  SELL_INFO_TYPE;     -- INPUT
  T_BOND_TRADE BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- SELL INFO
  T_SELL_INFO := NEW SELL_INFO_TYPE('20121120'  -- �ŷ�����(�ܰ� PK)
                                  , 'TEST_0428' -- �ݵ��ڵ�(�ܰ� PK)
                                  , 'KR_��ǥä' -- �����ڵ�(�ܰ� PK)
                                  , '20121120'  -- �ż�����(�ܰ� PK)
                                  , 10623       -- �ż��ܰ�(�ܰ� PK)
                                  , 1           -- �ܰ��Ϸù�ȣ(�ܰ� PK)
                                  , 0           -- �ŵ��ܰ�
                                  , 0           -- �ŵ�����
                                  , 0           -- ǥ��������
                                  , ''          -- �����ϱ���(1.����, 2.����)
                                  );
  
  -- �ܰ� ����
  PR_ADD_BALANCE(T_SELL_INFO, '20130520', T_BOND_TRADE);
    
END;