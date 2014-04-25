CREATE OR REPLACE PROCEDURE ISS.PR_DAMAGE_BOND (
  I_TRD_DATE     IN CHAR(8)
, I_BOND_CODE    IN CHAR(12)
, I_DAMAGE_PRICE IN NUMBER
, O_BOND_DAMAGE  OUT BOND_DAMAGE%ROWTYPE          -- ROWTYPE : �ջ󳻿�
) IS
  -- TYPE
  T_EVENT_INFO     EVENT_INFO_TYPE;               -- TYPE    : �̺�Ʈ INPUT
  T_EVENT_RESULT   EVENT_RESULT_EIR%ROWTYPE;      -- ROWTYPE : �̺�Ʈ OUTPUT
  T_BOND_BALANCE   BOND_BALANCE%ROWTYPE;          -- ROWTYPE : �ܰ�
  
  -- CURSOR : �ܰ�
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_TRD_DATE   -- �ŷ�����(�ܰ� PK)
       AND BOND_CODE = I_BOND_CODE  -- �����ڵ�(�ܰ� PK)
       AND BOOK_AMT  > 0;           -- ��αݾ�(0�̻��� ��)
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)�Է°� ����(INPUT �ʵ�)
  --   I_TRD_DATE     -- �ŷ�����
  --   I_BOND_CODE    -- �����ڵ�
  --   I_DAMAGE_PRICE -- �ջ�ܰ�
  ----------------------------------------------------------------------------------------------------
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)�ܰ� �ջ� ó��
  --   * �ջ�� ������ ������ �ִ� �ܰ� ��ȸ
  --   * LOOP�� �ѰǾ� �ջ� ó��
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_BALANCE_CUR;
    LOOP
      FETCH C_BOND_BALANCE_CUR INTO T_BOND_BALANCE;
      EXIT WHEN C_BOND_BALANCE_CUR%NOTFOUND;
      
      ----------------------------------------------------------------------------------------------------
      -- 3)�����ʱ�ȭ
      --   * Object���� �ʱ�ȭ �� Default������ ������
      ----------------------------------------------------------------------------------------------------
      PKG_EIR_NESTED_NSC.PR_EVENT_INFO_TYPE_INIT(T_EVENT_INFO);
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 4)�ջ� ó�� ���ν��� ȣ��
      --   * INPUT ����
      --   * ��ǥ �����, ������ ����
      ----------------------------------------------------------------------------------------------------
      T_EVENT_INFO.FUND_CODE  := T_BOND_BALANCE.FUND_CODE; -- �ݵ��ڵ�(�ܰ� PK)
      T_EVENT_INFO.BOND_CODE  := T_BOND_BALANCE.BOND_CODE; -- �����ڵ�(�ܰ� PK)
      T_EVENT_INFO.BUY_DATE   := T_BOND_BALANCE.BIZ_DATE;  -- �ż�����(�ܰ� PK)
      T_EVENT_INFO.BUY_PRICE  := T_BOND_BALANCE.BUY_PRICE; -- �ż��ܰ�(�ܰ� PK)
      T_EVENT_INFO.BALAN_SEQ  := T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
      T_EVENT_INFO.EVENT_DATE := I_TRD_DATE;               -- �̺�Ʈ��
      T_EVENT_INFO.EVENT_TYPE := '4';                      -- Event����(1.�ż�, 2.�ŵ�, 3.�ݸ�����, 4.�ջ�, 5.ȸ��)
      T_EVENT_INFO.DL_UV      := I_DAMAGE_PRICE;           -- �ŷ��ܰ�
      
      PKG_EIR_NESTED_NSC.PR_APPLY_ADD_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 5)�ջ󳻿� ���
      --   * �ջ󳻿� TABLE�� ���� ���
      ----------------------------------------------------------------------------------------------------
      O_BOND_DAMAGE.DAMAGE_DT := I_TRD_DATE; -- �ջ�����(PK)
      
      -- �ŷ��Ϸù�ȣ ä�� RULE //
      SELECT NVL(MAX(DAMAGE_SEQ), 0) + 1 AS DAMAGE_SEQ
        INTO O_BOND_DAMAGE.DAMAGE_SEQ                    -- �ջ��Ϸù�ȣ(PK)
        FROM BOND_DAMAGE
       WHERE DAMAGE_DT = I_TRD_DATE;
      -- // END
      
      O_BOND_DAMAGE.FUND_CODE      := T_BOND_BALANCE.FUND_CODE; -- �ݵ��ڵ�
      O_BOND_DAMAGE.BOND_CODE      := T_BOND_BALANCE.BOND_CODE; -- �����ڵ�
      O_BOND_DAMAGE.BUY_DATE       := T_BOND_BALANCE.BUY_DATE;  -- �ż�����
      O_BOND_DAMAGE.BUY_PRICE      := T_BOND_BALANCE.BUY_PRICE; -- �ż��ܰ�
      O_BOND_DAMAGE.BALAN_SEQ      := T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ
      O_BOND_DAMAGE.REDUCTION_AM   := ; -- ���ױݾ�
      
      -- INSERT : �ջ󳻿� ���
      INSERT INTO BOND_DAMAGE VALUES O_BOND_DAMAGE;
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 6)�ܰ� ������Ʈ
      --   * �ջ�� �ܰ��� ����Ǵ� �κ� ������Ʈ
      ----------------------------------------------------------------------------------------------------
      T_BOND_BALANCE.BOOK_AMT := ; -- ��αݾ�
      T_BOND_BALANCE.BOOK_PRC_AMT := ; -- ��ο���
      T_BOND_BALANCE.BTRM_UNPAID_INT := ; -- �̼�����
      T_BOND_BALANCE.SANGGAK_AMT := ; -- ���λ�����
      
      -- UPDATE : �ܰ� ������Ʈ
      UPDATE BOND_BALANCE 
         SET ROW = T_BOND_BALANCE
       WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- ��������(�ܰ� PK)
         AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
         AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- �����ڵ�(�ܰ� PK)
         AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- �ż�����(�ܰ� PK)
         AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
         AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
      
    END LOOP;
  CLOSE C_BOND_BALANCE_CUR;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('PR_DAMAGE_BOND END');
  
END;