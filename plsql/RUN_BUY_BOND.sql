DECLARE
  T_BUY_INFO   BUY_INFO_TYPE;    -- INPUT
  T_BOND_TRADE BOND_TRADE%ROWTYPE; -- OUTPUT
BEGIN
  -- BUY INFO
  T_BUY_INFO := NEW BUY_INFO_TYPE('20130516'     -- �ŷ�����
                                  , 'KR_FUND'    -- �ݵ��ڵ�
                                  , 'KR_�ܸ�ä'  -- �����ڵ�
                                  , 10623        -- �ż��ܰ�
                                  , 100000       -- �ż�����
                                  , 0.108        -- ǥ��������
                                  , '1'          -- �����ϱ���(1.����, 2.����)
                                  );
  
  -- ä�� �ż�
  PR_BUY_BOND(T_BUY_INFO, T_BOND_TRADE);
    
END;