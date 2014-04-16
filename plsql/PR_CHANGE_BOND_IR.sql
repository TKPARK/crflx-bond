CREATE OR REPLACE PROCEDURE ISS.PR_CHANGE_BOND_IR (
  I_CHANGE_INFO IN  CHANGE_BOND_IR_INFO_TYPE -- TYPE : ������ ���� ����
, O_BOND_TRADE  OUT BOND_TRADE%ROWTYPE       -- ROWTYPE : �ŷ�����
) IS
  -- TYPE
  T_EVENT_INFO      EVENT_INFO_TYPE;         -- TYPE    : �̺�Ʈ INPUT
  
  -- CURSOR : �ܰ�
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_CHANGE_INFO.TRD_DATE   -- �ŷ�����(�ܰ� PK)
       AND FUND_CODE = I_CHANGE_INFO.FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
       AND BOND_CODE = I_CHANGE_INFO.BOND_CODE  -- �����ڵ�(�ܰ� PK)
       AND BUY_DATE  = I_CHANGE_INFO.BUY_DATE   -- �ż�����(�ܰ� PK)
       AND BUY_PRICE = I_CHANGE_INFO.BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
       AND BALAN_SEQ = I_CHANGE_INFO.BALAN_SEQ  -- �ܰ��Ϸù�ȣ(�ܰ� PK)
       FOR UPDATE;
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)�Է°� ����(INPUT �ʵ�)
  --   TRD_DATE   -- �ŷ�����(�ܰ� PK)
  --   FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
  --   BOND_CODE  -- �����ڵ�(�ܰ� PK)
  --   BUY_DATE   -- �ż�����(�ܰ� PK)
  --   BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
  --   BALAN_SEQ  -- �ܰ��Ϸù�ȣ(�ܰ� PK)
  --   BOND_IR    -- ǥ��������
  ----------------------------------------------------------------------------------------------------
  -- ǥ��������
  IF I_CHANGE_INFO.BOND_IR <= 0 THEN
    PCZ_RAISE(-20999, 'ǥ�������� ����');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)�ܰ� Ȯ��
  --   * �ܰ� ���� Ȯ��
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_BALANCE_CUR;
    FETCH C_BOND_BALANCE_CUR INTO T_BOND_BALANCE;
    IF C_BOND_BALANCE_CUR%NOTFOUND THEN
      CLOSE C_BOND_BALANCE_CUR;
      RAISE_APPLICATION_ERROR(-20011, '�ܰ� ����');
    END IF;
  CLOSE C_BOND_BALANCE_CUR;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3)�����ʱ�ȭ
  --   * Object���� �ʱ�ȭ �� Default������ ������
  ----------------------------------------------------------------------------------------------------
  PR_INIT_EVENT_INFO(T_EVENT_INFO);
  PR_INIT_BOND_TRADE(O_BOND_TRADE);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)������ ���� ó�� ���ν��� ȣ��
  --   * INPUT ����
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := I_CHANGE_INFO.FUND_CODE; -- �ݵ��ڵ�(�ܰ� PK)
  T_EVENT_INFO.BOND_CODE  := I_CHANGE_INFO.BOND_CODE; -- �����ڵ�(�ܰ� PK)
  T_EVENT_INFO.BUY_DATE   := I_CHANGE_INFO.BUY_DATE;  -- �ż�����(�ܰ� PK)
  T_EVENT_INFO.BUY_PRICE  := I_CHANGE_INFO.BUY_PRICE; -- �ż��ܰ�(�ܰ� PK)
  T_EVENT_INFO.BALAN_SEQ  := I_CHANGE_INFO.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
  T_EVENT_INFO.EVENT_DATE := I_CHANGE_INFO.TRD_DATE;  -- �̺�Ʈ��
  T_EVENT_INFO.IR         := I_CHANGE_INFO.BOND_IR;   -- ǥ��������
  
  PKG_EIR_NESTED_NSC.PR_APPLY_CHANG_IR_EVENT(T_EVENT_INFO);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5)
  --   * 
  --   * 
  --   * 
  ----------------------------------------------------------------------------------------------------
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 6)
  --   * 
  ----------------------------------------------------------------------------------------------------
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 7)
  ----------------------------------------------------------------------------------------------------
  
  
  
  DBMS_OUTPUT.PUT_LINE('PR_CHANGE_BOND_IR END');
  
END;