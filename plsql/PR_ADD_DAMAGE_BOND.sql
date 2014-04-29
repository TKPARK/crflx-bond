CREATE OR REPLACE PROCEDURE ISS.PR_ADD_DAMAGE_BOND (
  I_TRD_DATE        IN  CHAR
, I_BOND_CODE       IN  CHAR
, I_DAMAGE_PRICE    IN  NUMBER
, I_ADD_DAMAGE_TYPE IN  CHAR   -- �ջ󱸺�(2.�߰��ջ�, 3. ȯ��)
, O_PRO_CN          OUT NUMBER -- ó���Ǽ�
) IS
  -- TYPE
  T_BOND_BALANCE   BOND_BALANCE%ROWTYPE;          -- ROWTYPE : �ܰ�
  T_BOND_DAMAGE    BOND_DAMAGE%ROWTYPE;           -- ROWTYPE : �ջ󳻿�
  
  -- CURSOR : �ܰ�
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_TRD_DATE  -- �ŷ�����(�ܰ� PK)
       AND BOND_CODE = I_BOND_CODE -- �����ڵ�(�ܰ� PK)
       AND DAMAGE_YN = 'Y'         -- �ջ󿩺�(N�� �ܰ�)
       AND TOT_QTY   > 0;          -- ���ܰ����(0�̻��� ��)
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
      -- 3)�ܰ� Validation
      --   * 
      ----------------------------------------------------------------------------------------------------
      
      
      ----------------------------------------------------------------------------------------------------
      -- 4)�ջ󳻿� ���
      --   * �ջ��� �߰��ջ�/ȯ�Խô� ���ױݾ׸� ����
      ----------------------------------------------------------------------------------------------------
      PR_INIT_BOND_DAMAGE(T_BOND_DAMAGE);
      
      T_BOND_DAMAGE.DAMAGE_DT := I_TRD_DATE;             -- �ջ�����(PK)
      
      -- �ŷ��Ϸù�ȣ ä�� RULE //
      SELECT NVL(MAX(DAMAGE_SEQ), 0) + 1 AS DAMAGE_SEQ
        INTO T_BOND_DAMAGE.DAMAGE_SEQ                    -- �ջ��Ϸù�ȣ(PK)
        FROM BOND_DAMAGE
       WHERE DAMAGE_DT = I_TRD_DATE;
      -- // END
      
      T_BOND_DAMAGE.FUND_CODE           := T_BOND_BALANCE.FUND_CODE;                                     -- �ݵ��ڵ�(�ܰ�PK)
      T_BOND_DAMAGE.BOND_CODE           := T_BOND_BALANCE.BOND_CODE;                                     -- �����ڵ�(�ܰ�PK)
      T_BOND_DAMAGE.BUY_DATE            := T_BOND_BALANCE.BUY_DATE;                                      -- �ż�����(�ܰ�PK)
      T_BOND_DAMAGE.BUY_PRICE           := T_BOND_BALANCE.BUY_PRICE;                                     -- �ż��ܰ�(�ܰ�PK)
      T_BOND_DAMAGE.BALAN_SEQ           := T_BOND_BALANCE.BALAN_SEQ;                                     -- �ܰ��Ϸù�ȣ(�ܰ�PK)
      T_BOND_DAMAGE.CANCEL_YN           := 'N';                                                          -- ��ҿ���(Y/N)
      T_BOND_DAMAGE.DAMAGE_TYPE         := I_ADD_DAMAGE_TYPE;                                            -- �ջ󱸺�(1.�ջ�, 2.�߰��ջ�, 3. ȯ��, 4.���)
      T_BOND_DAMAGE.DAMAGE_PRICE        := I_DAMAGE_PRICE;                                               -- �ջ�ܰ�
      T_BOND_DAMAGE.DAMAGE_QTY          := T_BOND_BALANCE.TOT_QTY;                                       -- �ջ����
      T_BOND_DAMAGE.DAMAGE_EVAL_AMT     := I_DAMAGE_PRICE * T_BOND_BALANCE.TOT_QTY / 10;                 -- �ջ��򰡱ݾ�(= ���� * �ջ�ܰ� / 10)
      
      -- 2.�߰��ջ�, 3.ȯ�� ó�� RULE //
      IF I_ADD_DAMAGE_TYPE = '2' THEN
        T_BOND_DAMAGE.REDUCTION_AM := ; -- ���ױݾ� = (��ο��� - �ջ��򰡱ݾ�)
      ELSIF I_ADD_DAMAGE_TYPE = '3' THEN
        T_BOND_DAMAGE.REDUCTION_AM := ; -- ���ױݾ� = ABS(��ο��� - �ջ��򰡱ݾ� - �� ���ױݾ�)
      END IF;
      -- // END
      
      -- INSERT : �ջ󳻿� ���
      INSERT INTO BOND_DAMAGE VALUES T_BOND_DAMAGE;
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 5)�ܰ� ������Ʈ
      --   * �ջ��� �߰��ջ�/ȯ�Խô� ���ױݾ׸� ����
      ----------------------------------------------------------------------------------------------------
      T_BOND_BALANCE.REDUCTION_AM    := T_BOND_DAMAGE.REDUCTION_AM; -- ���ױݾ�
      
      
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