DECLARE
  T_CHANGE_INFO  CHANGE_BOND_IR_INFO_TYPE; -- INPUT
  T_BOND_TRADE   BOND_TRADE%ROWTYPE;       -- OUTPUT
BEGIN
  -- CHANGE INFO
  T_CHANGE_INFO := NEW CHANGE_BOND_IR_INFO_TYPE('20130516'  -- �ŷ�����(�ܰ� PK)
                                              , 'KR_FUND'   -- �ݵ��ڵ�(�ܰ� PK)
                                              , 'KR_�ܸ�ä' -- �����ڵ�(�ܰ� PK)
                                              , '20130516'  -- �ż�����(�ܰ� PK)
                                              , 10623       -- �ż��ܰ�(�ܰ� PK)
                                              , 1           -- �ܰ��Ϸù�ȣ(�ܰ� PK)
                                              , 0.108       -- ǥ��������
                                              );
  
  -- ������ ����
  PR_CHANGE_BOND_IR(T_CHANGE_INFO, T_BOND_TRADE);
    
END;