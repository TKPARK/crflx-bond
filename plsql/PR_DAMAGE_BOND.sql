CREATE OR REPLACE PROCEDURE ISS.PR_DAMAGE_BOND (
  I_TRD_DATE     IN  CHAR
, I_BOND_CODE    IN  CHAR
, I_DAMAGE_PRICE IN  NUMBER
, O_PRO_CN       OUT NUMBER -- ó���Ǽ�
) IS
  -- TYPE
  T_EVENT_INFO     EVENT_INFO_TYPE;               -- TYPE    : �̺�Ʈ INPUT
  T_EVENT_RESULT   EVENT_RESULT_EIR%ROWTYPE;      -- ROWTYPE : �̺�Ʈ OUTPUT
  T_BOND_BALANCE   BOND_BALANCE%ROWTYPE;          -- ROWTYPE : �ܰ�
  T_BOND_DAMAGE    BOND_DAMAGE%ROWTYPE;           -- ROWTYPE : �ջ󳻿�
  
  -- CURSOR : �ܰ�
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_TRD_DATE   -- �ŷ�����(�ܰ� PK)
       AND BOND_CODE = I_BOND_CODE  -- �����ڵ�(�ܰ� PK)
       AND TOT_QTY  > 0             -- ���ܰ����(0�̻��� ��)
       AND DAMAGE_YN = 'N'          -- �ջ󿩺�(N�� �ܰ�)
       FOR UPDATE;
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
      -- 4)�����ʱ�ȭ
      --   * Object���� �ʱ�ȭ �� Default������ ������
      ----------------------------------------------------------------------------------------------------
      PKG_EIR_NESTED_NSC.PR_EVENT_INFO_TYPE_INIT(T_EVENT_INFO);
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 5)�ջ� ó�� ���ν��� ȣ��
      --   * INPUT ����
      --   * ��ǥ �����, ������ ����
      ----------------------------------------------------------------------------------------------------
      T_EVENT_INFO.FUND_CODE  := T_BOND_BALANCE.FUND_CODE; -- �ݵ��ڵ�(�ܰ� PK)
      T_EVENT_INFO.BOND_CODE  := T_BOND_BALANCE.BOND_CODE; -- �����ڵ�(�ܰ� PK)
      T_EVENT_INFO.BUY_DATE   := T_BOND_BALANCE.BUY_DATE;  -- �ż�����(�ܰ� PK)
      T_EVENT_INFO.BUY_PRICE  := T_BOND_BALANCE.BUY_PRICE; -- �ż��ܰ�(�ܰ� PK)
      T_EVENT_INFO.BALAN_SEQ  := T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
      T_EVENT_INFO.EVENT_DATE := I_TRD_DATE;               -- �̺�Ʈ��
      T_EVENT_INFO.EVENT_TYPE := '4';                      -- Event����(1.�ż�, 2.�ŵ�, 3.�ݸ�����, 4.�ջ�, 5.ȸ��)
      T_EVENT_INFO.DL_UV      := I_DAMAGE_PRICE;           -- �ŷ��ܰ�
      T_EVENT_INFO.DL_QT      := T_BOND_BALANCE.TOT_QTY;   -- �ŷ�����
      T_EVENT_INFO.IR         := T_BOND_BALANCE.BOND_IR;   -- ǥ��������
      
      PKG_EIR_NESTED_NSC.PR_APPLY_ADD_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 6)�ջ󳻿� ���
      --   * �ջ󳻿� TABLE�� ���� ���
      ----------------------------------------------------------------------------------------------------
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
      T_BOND_DAMAGE.DAMAGE_TYPE         := '1';                                                          -- �ջ󱸺�(1.�ջ�, 2.�߰��ջ�, 3. ȯ��, 4.���)
      T_BOND_DAMAGE.DAMAGE_PRICE        := I_DAMAGE_PRICE;                                               -- �ջ�ܰ�
      T_BOND_DAMAGE.DAMAGE_QTY          := T_BOND_BALANCE.TOT_QTY;                                       -- �ջ����
      T_BOND_DAMAGE.DAMAGE_EVAL_AMT     := I_DAMAGE_PRICE * T_BOND_BALANCE.TOT_QTY / 10;                 -- �ջ��򰡱ݾ�(= ���� * �ջ�ܰ� / 10)
      T_BOND_DAMAGE.CHBF_BOOK_AMT       := T_BOND_BALANCE.BOOK_AMT;                                      -- ������ ��αݾ�
      T_BOND_DAMAGE.CHBF_BOOK_PRC_AMT   := T_BOND_BALANCE.BOOK_PRC_AMT;                                  -- ������ ��ο���
      T_BOND_DAMAGE.CHAF_BOOK_AMT       := T_BOND_BALANCE.BOOK_PRC_AMT + T_EVENT_RESULT.SANGGAK_AMT;     -- ������ ��αݾ�
      T_BOND_DAMAGE.CHAF_BOOK_PRC_AMT   := T_BOND_BALANCE.BOOK_PRC_AMT + T_EVENT_RESULT.SANGGAK_AMT;     -- ������ ��ο���
      T_BOND_DAMAGE.ACCRUED_INT         := T_BOND_BALANCE.ACCRUED_INT;                                   -- �������
      T_BOND_DAMAGE.TTRM_UNPAID_INT     := T_EVENT_RESULT.TOT_INT - T_BOND_BALANCE.ACCRUED_INT - T_BOND_BALANCE.BTRM_UNPAID_INT; -- ���̼�����(= ������ - ������� - ��.�̼�����)
      T_BOND_DAMAGE.BTRM_UNPAID_INT     := T_BOND_BALANCE.BTRM_UNPAID_INT + T_BOND_DAMAGE.TTRM_BOND_INT; -- ����̼�����
      
      -- ���λ󰢱ݾ�, �����󰢱ݾ� RULE //
      IF T_EVENT_RESULT.SANGGAK_AMT > 0 THEN
        T_BOND_DAMAGE.EX_CHA_SANGGAK_AMT  := T_EVENT_RESULT.SANGGAK_AMT;                                 -- �����󰢱ݾ�
      ELSE
        T_BOND_DAMAGE.DSCT_SANGGAK_AMT    := T_EVENT_RESULT.SANGGAK_AMT * -1;                            -- ���λ󰢱ݾ�
      END IF;
      -- // END
      
      T_BOND_DAMAGE.CHBF_BTRM_EVAL_PRFT := T_BOND_BALANCE.BTRM_EVAL_PRFT;                                -- ������ ����������
      T_BOND_DAMAGE.CHBF_BTRM_EVAL_LOSS := T_BOND_BALANCE.BTRM_EVAL_LOSS;                                -- ������ �����򰡼ս�
      
      T_BOND_DAMAGE.REDUCTION_AM        := T_BOND_DAMAGE.BOOK_PRC_AMT - T_BOND_DAMAGE.DAMAGE_EVAL_AMT;   -- ���ױݾ�(= ��ο��� - �ջ��򰡱ݾ�)
      
      -- INSERT : �ջ󳻿� ���
      INSERT INTO BOND_DAMAGE VALUES T_BOND_DAMAGE;
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 7)�ܰ� ������Ʈ
      --   * �ջ�� �ܰ��� ����Ǵ� �κ� ������Ʈ
      ----------------------------------------------------------------------------------------------------
      T_BOND_BALANCE.BOOK_AMT        := T_BOND_DAMAGE.BOOK_AMT;                                  -- ��αݾ�
      T_BOND_BALANCE.BOOK_PRC_AMT    := T_BOND_DAMAGE.BOOK_PRC_AMT;                              -- ��ο���
      T_BOND_BALANCE.BTRM_UNPAID_INT := T_BOND_DAMAGE.BTRM_UNPAID_INT;                           -- �̼�����
      T_BOND_BALANCE.SANGGAK_AMT     := T_BOND_BALANCE.SANGGAK_AMT + T_EVENT_RESULT.SANGGAK_AMT; -- �󰢱ݾ�
      T_BOND_BALANCE.BTRM_EVAL_PRFT  := 0;                                                       -- ����������
      T_BOND_BALANCE.BTRM_EVAL_LOSS  := 0;                                                       -- �����򰡼ս�
      T_BOND_BALANCE.DAMAGE_YN       := 'Y'                                                      -- �ջ󿩺�(Y/N)
      T_BOND_BALANCE.DAMAGE_DT       := T_BOND_DAMAGE.DAMAGE_DT;                                 -- �ջ�����
      T_BOND_BALANCE.REDUCTION_AM    := T_BOND_DAMAGE.REDUCTION_AM;                              -- ���ױݾ�
      
      
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