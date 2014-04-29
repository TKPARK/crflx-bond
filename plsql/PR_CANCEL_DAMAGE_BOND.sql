CREATE OR REPLACE PROCEDURE ISS.PR_CANCEL_DAMAGE_BOND (
  I_DAMAGE_DT    IN  CHAR
, I_BOND_CODE    IN  CHAR
, I_DAMAGE_PRICE IN  NUMBER
, O_PRO_CN       OUT NUMBER -- ó���Ǽ�
) IS
  -- TYPE
  T_EVENT_INFO       EVENT_INFO_TYPE;               -- TYPE    : �̺�Ʈ INPUT
  T_EVENT_RESULT     EVENT_RESULT_EIR%ROWTYPE;      -- ROWTYPE : �̺�Ʈ OUTPUT
  T_ORGN_BOND_DAMAGE BOND_DAMAGE%ROWTYPE;           -- ROWTYPE : �ջ� ���ŷ�����
  T_BOND_DAMAGE      BOND_DAMAGE%ROWTYPE;           -- ROWTYPE : �ջ󳻿�
  T_BOND_BALANCE     BOND_BALANCE%ROWTYPE;          -- ROWTYPE : �ܰ�
  
  -- CURSOR : �ջ󳻿�
  CURSOR C_BOND_DAMAGE_CUR IS
    SELECT *
      FROM BOND_DAMAGE
     WHERE DAMAGE_DT    = I_DAMAGE_DT     -- �ջ�����
       AND BOND_CODE    = I_BOND_CODE     -- �����ڵ�
       AND DAMAGE_PRICE = I_DAMAGE_PRICE; -- �ջ�ܰ�
       
  -- CURSOR : �ܰ�
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = T_ORGN_BOND_DAMAGE.TRD_DATE   -- �ŷ�����(�ܰ� PK)
       AND FUND_CODE = T_ORGN_BOND_DAMAGE.FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
       AND BOND_CODE = T_ORGN_BOND_DAMAGE.BOND_CODE  -- �����ڵ�(�ܰ� PK)
       AND BUY_DATE  = T_ORGN_BOND_DAMAGE.BUY_DATE   -- �ż�����(�ܰ� PK)
       AND BUY_PRICE = T_ORGN_BOND_DAMAGE.BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
       AND BALAN_SEQ = T_ORGN_BOND_DAMAGE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)�Է°� ����(INPUT �ʵ�)
  --   I_DAMAGE_DT    -- �ջ�����
  --   I_BOND_CODE    -- �����ڵ�
  --   I_DAMAGE_PRICE -- �ջ�ܰ�
  ----------------------------------------------------------------------------------------------------
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)�ջ� ó���� ���� ���� ó��
  --   * �ջ󳻿��� ��ȸ�Ͽ� �ܰ� ���� ó��
  --   * LOOP�� �ѰǾ� �ջ� ó��
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_DAMAGE_CUR;
    LOOP
      FETCH C_BOND_DAMAGE_CUR INTO T_ORGN_BOND_DAMAGE;
      EXIT WHEN C_BOND_DAMAGE_CUR%NOTFOUND;
      
      ----------------------------------------------------------------------------------------------------
      -- 3)�����ʱ�ȭ
      --   * Object���� �ʱ�ȭ �� Default������ ������
      ----------------------------------------------------------------------------------------------------
      PKG_EIR_NESTED_NSC.PR_EVENT_INFO_TYPE_INIT(T_EVENT_INFO);
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 4)��� ó�� ���ν��� ȣ��
      --   * INPUT ����
      --   * EVENT_RESULT ���̺� ���ŷ����� ����
      ----------------------------------------------------------------------------------------------------
      T_EVENT_INFO.FUND_CODE  := T_ORGN_BOND_DAMAGE.FUND_CODE; -- �ݵ��ڵ�(�ܰ� PK)
      T_EVENT_INFO.BOND_CODE  := T_ORGN_BOND_DAMAGE.BOND_CODE; -- �����ڵ�(�ܰ� PK)
      T_EVENT_INFO.BUY_DATE   := T_ORGN_BOND_DAMAGE.BUY_DATE;  -- �ż�����(�ܰ� PK)
      T_EVENT_INFO.BUY_PRICE  := T_ORGN_BOND_DAMAGE.BUY_PRICE; -- �ż��ܰ�(�ܰ� PK)
      T_EVENT_INFO.BALAN_SEQ  := T_ORGN_BOND_DAMAGE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
      T_EVENT_INFO.EVENT_DATE := T_ORGN_BOND_DAMAGE.TRD_DATE;  -- �̺�Ʈ��
      T_EVENT_INFO.EVENT_SEQ  := T_ORGN_BOND_DAMAGE.EVENT_SEQ; -- �̺�Ʈ SEQ
      
      PKG_EIR_NESTED_NSC.PR_CANCEL_EVENT(T_EVENT_INFO);
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 5)�ܰ� ��ȸ
      --   * �ջ󳻿��� ������ �ܰ� ��ȸ
      ----------------------------------------------------------------------------------------------------
      OPEN C_BOND_BALANCE_CUR;
        FETCH C_BOND_BALANCE_CUR INTO T_BOND_BALANCE;
        IF C_BOND_BALANCE_CUR%NOTFOUND THEN
          CLOSE C_BOND_BALANCE_CUR;
          RAISE_APPLICATION_ERROR(-20011, '�ܰ� ����');
        END IF;
      CLOSE C_BOND_BALANCE_CUR;
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 6)�ܰ� ����
      --   * �ջ� ó���� ���� �ܰ� ����
      ----------------------------------------------------------------------------------------------------
      T_BOND_BALANCE.BOOK_AMT        := T_ORGN_BOND_DAMAGE.CHBF_BOOK_AMT;       -- ��αݾ�
      T_BOND_BALANCE.BOOK_PRC_AMT    := T_ORGN_BOND_DAMAGE.CHBF_BOOK_PRC_AMT;   -- ��ο���
      T_BOND_BALANCE.BTRM_UNPAID_INT := T_ORGN_BOND_DAMAGE.BTRM_UNPAID_INT;     -- �̼�����
      T_BOND_BALANCE.SANGGAK_AMT     := T_BOND_BALANCE.SANGGAK_AMT + (T_ORGN_BOND_TRADE.DSCT_SANGGAK_AMT - T_ORGN_BOND_TRADE.EX_CHA_SANGGAK_AMT); -- �󰢱ݾ�
      T_BOND_BALANCE.BTRM_EVAL_PRFT  := T_ORGN_BOND_DAMAGE.CHBF_BTRM_EVAL_PRFT; -- ����������
      T_BOND_BALANCE.BTRM_EVAL_LOSS  := T_ORGN_BOND_DAMAGE.CHBF_BTRM_EVAL_LOSS; -- �����򰡼ս�
      T_BOND_BALANCE.DAMAGE_YN       := 'N';                                    -- �ջ󿩺�(Y/N)
      T_BOND_BALANCE.DAMAGE_DT       := '';                                     -- �ջ�����
      T_BOND_BALANCE.REDUCTION_AM    := 0;                                      -- ���ױݾ�
      
      
      -- UPDATE : �ܰ� ������Ʈ
      UPDATE BOND_BALANCE 
         SET ROW = T_BOND_BALANCE
       WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- ��������(�ܰ� PK)
         AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
         AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- �����ڵ�(�ܰ� PK)
         AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- �ż�����(�ܰ� PK)
         AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
         AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
      
      
      ----------------------------------------------------------------------------------------------------
      -- 7)���ŷ����� ���ó��
      --   * ��ҿ��� 'Y' ������ ������Ʈ
      ----------------------------------------------------------------------------------------------------
      T_ORGN_BOND_DAMAGE.CANCEL_YN := 'Y'; -- ��ҿ���(Y/N)
      
      -- UPDATE : �ջ󳻿� ������Ʈ
      UPDATE BOND_DAMAGE 
         SET ROW = T_ORGN_BOND_DAMAGE
       WHERE DAMAGE_DT  = T_ORGN_BOND_DAMAGE.DAMAGE_DT   -- �ջ�����(PK)
         AND DAMAGE_SEQ = T_ORGN_BOND_DAMAGE.DAMAGE_SEQ; -- �ջ��Ϸù�ȣ(PK)
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 8)��Ұŷ����� ���
      ----------------------------------------------------------------------------------------------------
      PR_INIT_BOND_DAMAGE(T_BOND_DAMAGE);
      
      T_BOND_DAMAGE.DAMAGE_DT := I_DAMAGE_DT;                -- �ջ�����(PK)
      -- �ŷ��Ϸù�ȣ ä�� RULE //
      SELECT NVL(MAX(DAMAGE_SEQ), 0) + 1 AS DAMAGE_SEQ
        INTO T_BOND_DAMAGE.DAMAGE_SEQ                        -- �ջ��Ϸù�ȣ(PK)
        FROM BOND_DAMAGE
       WHERE DAMAGE_DT = I_DAMAGE_DT;
      -- // END
      T_BOND_DAMAGE.FUND_CODE   := T_BOND_BALANCE.FUND_CODE; -- �ݵ��ڵ�
      T_BOND_DAMAGE.BOND_CODE   := T_BOND_BALANCE.BOND_CODE; -- �����ڵ�
      T_BOND_DAMAGE.BUY_DATE    := T_BOND_BALANCE.BUY_DATE;  -- �ż�����
      T_BOND_DAMAGE.BUY_PRICE   := T_BOND_BALANCE.BUY_PRICE; -- �ż��ܰ�
      T_BOND_DAMAGE.BALAN_SEQ   := T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ
  
      T_BOND_DAMAGE.CANCEL_YN   := 'Y';                      -- ��ҿ���(Y/N)
      T_BOND_DAMAGE.DAMAGE_TYPE := '4';                      -- �ջ󱸺�(1.�ջ�, 2.�߰��ջ�, 3. ȯ��, 4.���)
      
      -- INSERT : �ջ󳻿� ���
      INSERT INTO BOND_DAMAGE VALUES T_BOND_DAMAGE;
      
      
      
    END LOOP;
  CLOSE C_BOND_DAMAGE_CUR;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('PR_DAMAGE_BOND END');
  
END;