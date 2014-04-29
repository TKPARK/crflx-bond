DECLARE
  T_CHANGE_INFO  CHANGE_BOND_IR_INFO_TYPE; -- INPUT
  T_BOND_TRADE   BOND_TRADE%ROWTYPE;       -- OUTPUT
BEGIN
  -- CHANGE INFO
  T_CHANGE_INFO := NEW CHANGE_BOND_IR_INFO_TYPE('20130520'  -- �ŷ�����(�ܰ� PK)
                                              , 'TEST_0428' -- �ݵ��ڵ�(�ܰ� PK)
                                              , 'KR_��ǥä' -- �����ڵ�(�ܰ� PK)
                                              , '20121120'  -- �ż�����(�ܰ� PK)
                                              , 10623       -- �ż��ܰ�(�ܰ� PK)
                                              , 1           -- �ܰ��Ϸù�ȣ(�ܰ� PK)
                                              , 0.106       -- ǥ��������
                                              );
  
  -- ������ ����
  PR_CHANGE_BOND_IR(T_CHANGE_INFO, T_BOND_TRADE);
    
END;