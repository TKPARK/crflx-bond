CREATE OR REPLACE PROCEDURE ISS.PR_SELL_BOND (
  I_SELL_INFO  IN  SELL_INFO_TYPE                 -- TYPE    : �ŵ�����
, O_BOND_TRADE OUT BOND_TRADE%ROWTYPE             -- ROWTYPE : �ŷ�����
) IS
  -- TYPE
  T_EVENT_INFO     EVENT_INFO_TYPE;               -- TYPE    : �̺�Ʈ INPUT
  T_EVENT_RESULT   EVENT_RESULT_EIR%ROWTYPE;      -- ROWTYPE : �̺�Ʈ OUTPUT
  T_BOND_BALANCE   BOND_BALANCE%ROWTYPE;          -- ROWTYPE : �ܰ�
  T_BOND_INFO      BOND_INFO%ROWTYPE;             -- ROWTYPE : ����
  
  -- �������� �ʵ�
  T_BF_INT_DATE    CHAR(8) := '';-- ��������������
  T_TOT_INT_DAYS   NUMBER  := 0; -- �������ϼ�
  T_TRD_PR_LO      NUMBER  := 0; -- �Ÿż���
  
  -- CURSOR : ����
  CURSOR C_BOND_INFO_CUR IS
    SELECT *
      FROM BOND_INFO
     WHERE BOND_CODE = I_SELL_INFO.BOND_CODE;
  -- CURSOR : �ܰ�
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_SELL_INFO.TRD_DATE   -- �ŷ�����(�ܰ� PK)
       AND FUND_CODE = I_SELL_INFO.FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
       AND BOND_CODE = I_SELL_INFO.BOND_CODE  -- �����ڵ�(�ܰ� PK)
       AND BUY_DATE  = I_SELL_INFO.BUY_DATE   -- �ż�����(�ܰ� PK)
       AND BUY_PRICE = I_SELL_INFO.BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
       AND BALAN_SEQ = I_SELL_INFO.BALAN_SEQ  -- �ܰ��Ϸù�ȣ(�ܰ� PK)
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
  --   SELL_PRICE -- �ŵ��ܰ�
  --   SELL_QTY   -- �ŵ�����
  --   STL_DT_TP  -- �����ϱ���(1.����, 2.����)
  ----------------------------------------------------------------------------------------------------
  -- �ŵ��ܰ�
  IF I_SELL_INFO.SELL_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '�ŵ��ܰ� ����');
  END IF;
  -- �ŵ�����
  IF I_SELL_INFO.SELL_QTY <= 0 THEN
    PCZ_RAISE(-20999, '�ŵ����� ����');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)���� �� �ܰ� Ȯ��
  --   * ���� ���� Ȯ��
  --   * �ܰ� ���� Ȯ��
  --   * �����ϱ��п� ���� ����, ���� ������� Ȯ��
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_INFO_CUR;
    FETCH C_BOND_INFO_CUR INTO T_BOND_INFO;
    IF C_BOND_INFO_CUR%NOTFOUND THEN
      CLOSE C_BOND_INFO_CUR;
      RAISE_APPLICATION_ERROR(-20011, '���� ����');
    END IF;
  CLOSE C_BOND_INFO_CUR;
  
  OPEN C_BOND_BALANCE_CUR;
    FETCH C_BOND_BALANCE_CUR INTO T_BOND_BALANCE;
    IF C_BOND_BALANCE_CUR%NOTFOUND THEN
      CLOSE C_BOND_BALANCE_CUR;
      RAISE_APPLICATION_ERROR(-20011, '�ܰ� ����');
    END IF;
  CLOSE C_BOND_BALANCE_CUR;
  
  IF I_SELL_INFO.STL_DT_TP = '1' THEN
    IF I_SELL_INFO.SELL_QTY > T_BOND_BALANCE.TDY_AVAL_QTY THEN
      RAISE_APPLICATION_ERROR(-20011, '���ϰ������ ����');
    END IF;
  ELSIF I_SELL_INFO.STL_DT_TP = '2' THEN
    IF I_SELL_INFO.SELL_QTY > T_BOND_BALANCE.NDY_AVAL_QTY THEN
      RAISE_APPLICATION_ERROR(-20011, '���ϰ������ ����');
    END IF;
  END IF;
  
  -- �������� RULE //
  -- 1.���� : �������� = �ŵ�����
  -- 2.���� : �������� = ������ ��� ���� ó��
  IF I_SELL_INFO.STL_DT_TP = '1' THEN
    O_BOND_TRADE.SETL_DATE := I_SELL_INFO.TRD_DATE;
  ELSIF I_SELL_INFO.STL_DT_TP = '2' THEN
    -- ������ ��� ���� ó��
    O_BOND_TRADE.SETL_DATE := TO_CHAR(TO_DATE(I_SELL_INFO.TRD_DATE, 'YYYYMMDD')+1, 'YYYYMMDD');
  END IF;
  -- // END
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3)�����ʱ�ȭ
  --   * Object���� �ʱ�ȭ �� Default������ ������
  ----------------------------------------------------------------------------------------------------
  PR_INIT_EVENT_INFO(T_EVENT_INFO);
  PR_INIT_EVENT_RESULT(T_EVENT_RESULT);
  PR_INIT_BOND_TRADE(O_BOND_TRADE);
  PR_INIT_BOND_INFO(T_BOND_INFO);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)�ŵ� ó�� ���ν��� ȣ��
  --   * INPUT ����
  --   * �󰢱ݾ׻���, ��ǥ �����, ������, ��αݾ׻���
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE           := T_BOND_BALANCE.FUND_CODE;                      -- �ݵ��ڵ�(�ܰ� PK)
  T_EVENT_INFO.BOND_CODE           := T_BOND_BALANCE.BOND_CODE;                      -- �����ڵ�(�ܰ� PK)
  T_EVENT_INFO.BUY_DATE            := T_BOND_BALANCE.BIZ_DATE;                       -- �ż�����(�ܰ� PK)
  T_EVENT_INFO.BUY_PRICE           := T_BOND_BALANCE.BUY_PRICE;                      -- �ż��ܰ�(�ܰ� PK)
  T_EVENT_INFO.BALAN_SEQ           := T_BOND_BALANCE.BALAN_SEQ;                      -- �ܰ��Ϸù�ȣ(�ܰ� PK)
  T_EVENT_INFO.EVENT_DATE          := O_BOND_TRADE.SETL_DATE;                        -- �̺�Ʈ��
  T_EVENT_INFO.EVENT_TYPE          := '2';                                           -- Event����(1.�ż�,2.�ŵ�,3.�ݸ�����,4.�ջ�,5.ȸ��)
  T_EVENT_INFO.DL_UV               := I_SELL_INFO.SELL_PRICE;                        -- �ŷ��ܰ�
  T_EVENT_INFO.DL_QT               := I_SELL_INFO.SELL_QTY;                          -- �ŷ�����
  T_EVENT_INFO.SELL_RT             := I_SELL_INFO.SELL_QTY / T_BOND_BALANCE.TOT_QTY; -- �ŵ���
  
  PKG_EIR_NESTED_NSC.PR_APPLY_ADD_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5)�ŷ����� ���(�������� ���)
  --   * T_EVENT_RESULT �����͸� ������ �������� ����
  --   * ���������� �ʿ��� ��ȸ �� ��� ���� ���� ����
  ----------------------------------------------------------------------------------------------------
  O_BOND_TRADE.TRD_DATE            := I_SELL_INFO.TRD_DATE;                          -- �ŷ�����(PK)
  
  -- �ŷ��Ϸù�ȣ ä�� RULE //
  SELECT NVL(MAX(TRD_SEQ), 0) + 1 AS TRD_SEQ
    INTO O_BOND_TRADE.TRD_SEQ                                                        -- �ŷ��Ϸù�ȣ(PK)
    FROM BOND_TRADE
   WHERE TRD_DATE = I_SELL_INFO.TRD_DATE;
  -- // END
  
  O_BOND_TRADE.FUND_CODE           := I_SELL_INFO.FUND_CODE;                         -- �ݵ��ڵ�
  O_BOND_TRADE.BOND_CODE           := I_SELL_INFO.BOND_CODE;                         -- �����ڵ�
  O_BOND_TRADE.BUY_DATE            := I_SELL_INFO.TRD_DATE;                          -- �ż�����
  O_BOND_TRADE.BUY_PRICE           := I_SELL_INFO.BUY_PRICE;                         -- �ż��ܰ�
  O_BOND_TRADE.BALAN_SEQ           := I_SELL_INFO.BALAN_SEQ;                         -- �ܰ��Ϸù�ȣ
  O_BOND_TRADE.TRD_TYPE_CD         := '3';                                           -- �Ÿ������ڵ�(1.�μ�, 2.���ż�, 3.���ŵ�, 4.��ȯ)
  O_BOND_TRADE.GOODS_BUY_SELL_SECT := '2';                                           -- ��ǰ�ż��ŵ�����(1.��ǰ�ż�, 2.��ǰ�ŵ�)
  O_BOND_TRADE.STT_TERM_SECT       := I_SELL_INFO.STL_DT_TP;                         -- �����Ⱓ����(0.����, 1.����)
  
  
  O_BOND_TRADE.EXPR_DATE   := T_BOND_INFO.EXPIRE_DATE;   -- ��������
  O_BOND_TRADE.EVENT_DATE  := T_EVENT_RESULT.EVENT_DATE; -- �̺�Ʈ��
  O_BOND_TRADE.EVENT_SEQ   := T_EVENT_RESULT.EVENT_SEQ;  -- �̺�ƮSEQ
  O_BOND_TRADE.TRD_PRICE   := I_SELL_INFO.SELL_PRICE;    -- �ŸŴܰ�
  O_BOND_TRADE.TRD_QTY     := I_SELL_INFO.SELL_QTY;      -- �Ÿż���
  O_BOND_TRADE.BOND_EIR    := T_BOND_BALANCE.BOND_EIR;   -- ��ȿ������
  O_BOND_TRADE.BOND_IR     := T_BOND_BALANCE.BOND_IR;    -- ǥ��������
  
  -- �����ڱݾ� �� ������� RULE //
  -- T_EVENT_RESULT���� ��� �� ���ϰ����� ������
--  O_BOND_TRADE.TOT_DCNT    := T_EVENT_RESULT.;           -- ���ϼ�(������ ~ ������)
--  O_BOND_TRADE.SRV_DCNT    := T_EVENT_RESULT.;           -- �����ϼ�(������ ~ ������)
--  O_BOND_TRADE.LPCNT       := T_EVENT_RESULT.;           -- ����ϼ�(������ ~ �����)
--  O_BOND_TRADE.HOLD_DCNT   := T_EVENT_RESULT.;           -- �����ϼ�(����� ~ ������)
  -- // END
  
  O_BOND_TRADE.TOT_INT      := T_EVENT_RESULT.TOT_INT;                                       -- �����ڱݾ�(�ŵ��׸� * ǥ�������� * �����ϼ� / 365)
  O_BOND_TRADE.ACCRUED_INT  := FN_AMOUNT(T_BOND_BALANCE.ACCRUED_INT * T_EVENT_INFO.SELL_RT); -- �������(�ܰ�.������� * �ŵ���)
  
  O_BOND_TRADE.TRD_FACE_AMT := FN_AMOUNT(O_BOND_TRADE.TRD_QTY * 1000);                       -- �Ÿž׸�(���� * 1000)
  O_BOND_TRADE.TRD_AMT      := TRUNC(O_BOND_TRADE.TRD_PRICE * O_BOND_TRADE.TRD_QTY / 10);    -- �Ÿűݾ�(���� * �ܰ� / 10)
  O_BOND_TRADE.TRD_NET_AMT  := FN_AMOUNT(O_BOND_TRADE.TRD_AMT - O_BOND_TRADE.ACCRUED_INT);   -- �Ÿ�����ݾ�(�Ÿűݾ� - �������)
  
  -- ���λ󰢱ݾ�, �����󰢱ݾ� RULE //
  IF T_EVENT_RESULT.SANGGAK_AMT > 0 THEN
    O_BOND_TRADE.DSCT_SANGGAK_AMT    := T_EVENT_RESULT.SANGGAK_AMT;      -- ���λ󰢱ݾ�
  ELSE
    O_BOND_TRADE.EX_CHA_SANGGAK_AMT  := T_EVENT_RESULT.SANGGAK_AMT * -1; -- �����󰢱ݾ�
  END IF;
  -- // END
  
  O_BOND_TRADE.BOOK_AMT        := FN_AMOUNT((T_BOND_BALANCE.BOOK_AMT + T_EVENT_RESULT.SANGGAK_AMT) * T_EVENT_INFO.SELL_RT);     -- ��αݾ�((�ܰ�.��αݾ� + �󰢾�) * �ŵ���)
  O_BOND_TRADE.BOOK_PRC_AMT    := FN_AMOUNT((T_BOND_BALANCE.BOOK_PRC_AMT + T_EVENT_RESULT.SANGGAK_AMT) * T_EVENT_INFO.SELL_RT); -- ��ο���((�ܰ�.��ο��� + �󰢾�) * �ŵ���)
  
  O_BOND_TRADE.BTRM_UNPAID_INT := FN_AMOUNT(T_BOND_BALANCE.BTRM_UNPAID_INT * T_EVENT_INFO.SELL_RT);                             -- ����̼�����(�ܰ�.����̼����� * �ŵ���)
  O_BOND_TRADE.TTRM_BOND_INT   := FN_AMOUNT(O_BOND_TRADE.TOT_INT - O_BOND_TRADE.ACCRUED_INT - O_BOND_TRADE.BTRM_UNPAID_INT);    -- ���ä������(�����ڱݾ�-������������� - ����̼�����������)
  
  -- �Ÿ�����, �Ÿżս� RULE //
  -- �Ÿż��� := �Ÿ�����ݾ�-��ο���������
  -- IF �Ÿż��� > 0 THEN
  --   �Ÿ����� = �Ÿż���, �Ÿżս� = 0;
  -- ELSE
  --   �Ÿ����� =        0, �Ÿżս� = �Ÿż���;
  -- END IF;
  T_TRD_PR_LO := O_BOND_TRADE.TRD_AMT-O_BOND_TRADE.BOOK_AMT-O_BOND_TRADE.TOT_INT;
  IF T_TRD_PR_LO > 0 THEN
  O_BOND_TRADE.TRD_PRFT        := T_TRD_PR_LO;                                   -- �Ÿ�����
  O_BOND_TRADE.TRD_LOSS        := 0;                                             -- �Ÿżս�
  ELSE
  O_BOND_TRADE.TRD_PRFT        := 0;                                             -- �Ÿ�����
  O_BOND_TRADE.TRD_LOSS        := T_TRD_PR_LO * -1;                              -- �Ÿżս�
  END IF;
  -- // END
  
  O_BOND_TRADE.TXSTD_AMT       := O_BOND_TRADE.TOT_INT - O_BOND_TRADE.ACCRUED_INT; -- ��ǥ�ݾ�(�����ڱݾ� - �������(�����Ⱓ ����))
  -- ���ݰ�� ���� ó��
  O_BOND_TRADE.CORP_TAX        := TRUNC(O_BOND_TRADE.TXSTD_AMT * 0.14, -1);        -- ���޹��μ�
  O_BOND_TRADE.UNPAID_CORP_TAX := TRUNC(O_BOND_TRADE.TXSTD_AMT * 0.14, -1);        -- �����޹��μ�
  
  -- INSERT : �ŷ����� ���
  INSERT INTO BOND_TRADE VALUES O_BOND_TRADE;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 6)�ܰ� ������Ʈ
  ----------------------------------------------------------------------------------------------------
  -- �ܰ���� RULE //
  IF I_SELL_INFO.STL_DT_TP = '1' THEN
    T_BOND_BALANCE.TOT_QTY         := T_BOND_BALANCE.TOT_QTY - O_BOND_TRADE.TRD_QTY;               -- ���ܰ����
    T_BOND_BALANCE.TDY_AVAL_QTY    := T_BOND_BALANCE.TDY_AVAL_QTY - O_BOND_TRADE.TRD_QTY;          -- ���ϰ������
    T_BOND_BALANCE.NDY_AVAL_QTY    := T_BOND_BALANCE.NDY_AVAL_QTY - O_BOND_TRADE.TRD_QTY;          -- ���ϰ������
  ELSIF I_SELL_INFO.STL_DT_TP = '2' THEN
    T_BOND_BALANCE.TOT_QTY         := T_BOND_BALANCE.TOT_QTY - O_BOND_TRADE.TRD_QTY;               -- ���ܰ����
    T_BOND_BALANCE.TDY_AVAL_QTY    := T_BOND_BALANCE.TDY_AVAL_QTY;                                 -- ���ϰ������
    T_BOND_BALANCE.NDY_AVAL_QTY    := T_BOND_BALANCE.NDY_AVAL_QTY - O_BOND_TRADE.TRD_QTY;          -- ���ϰ������
  END IF;
  -- // END
  
  T_BOND_BALANCE.BOOK_AMT        := (T_BOND_BALANCE.BOOK_AMT + T_EVENT_RESULT.SANGGAK_AMT) - O_BOND_TRADE.BOOK_AMT;         -- ��αݾ�
  T_BOND_BALANCE.BOOK_PRC_AMT    := (T_BOND_BALANCE.BOOK_PRC_AMT + T_EVENT_RESULT.SANGGAK_AMT) - O_BOND_TRADE.BOOK_PRC_AMT; -- ��ο���
  T_BOND_BALANCE.ACCRUED_INT     := T_BOND_BALANCE.ACCRUED_INT - O_BOND_TRADE.ACCRUED_INT;         -- �������
  T_BOND_BALANCE.BTRM_UNPAID_INT := T_BOND_BALANCE.BTRM_UNPAID_INT - O_BOND_TRADE.BTRM_UNPAID_INT; -- ����̼�����
  T_BOND_BALANCE.TTRM_BOND_INT   := T_BOND_BALANCE.TTRM_BOND_INT - O_BOND_TRADE.BTRM_UNPAID_INT;   -- ���ä������
  T_BOND_BALANCE.SANGGAK_AMT     := T_BOND_BALANCE.SANGGAK_AMT + T_EVENT_RESULT.SANGGAK_AMT;       -- �󰢱ݾ�
  T_BOND_BALANCE.MI_SANGGAK_AMT  := T_BOND_BALANCE.MI_SANGGAK_AMT - T_BOND_BALANCE.SANGGAK_AMT;    -- �̻󰢱ݾ�(�ܰ�.�̻󰢱ݾ�-�󰢱ݾ�)
  T_BOND_BALANCE.TRD_PRFT        := T_BOND_BALANCE.TRD_PRFT + O_BOND_TRADE.TRD_PRFT;               -- �Ÿ�����
  T_BOND_BALANCE.TRD_LOSS        := T_BOND_BALANCE.TRD_LOSS + O_BOND_TRADE.TRD_LOSS;               -- �Ÿżս�
  T_BOND_BALANCE.TXSTD_AMT       := T_BOND_BALANCE.TXSTD_AMT + O_BOND_TRADE.TXSTD_AMT;             -- ��ǥ�ݾ�
  T_BOND_BALANCE.CORP_TAX        := T_BOND_BALANCE.CORP_TAX + O_BOND_TRADE.CORP_TAX;               -- ���޹��μ�
  T_BOND_BALANCE.UNPAID_CORP_TAX := T_BOND_BALANCE.UNPAID_CORP_TAX + O_BOND_TRADE.UNPAID_CORP_TAX; -- �����޹��μ�
  
  -- UPDATE : �ܰ� ������Ʈ
  UPDATE BOND_BALANCE 
     SET ROW = T_BOND_BALANCE
   WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- ��������(�ܰ� PK)
     AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
     AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- �����ڵ�(�ܰ� PK)
     AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- �ż�����(�ܰ� PK)
     AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
     AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
  
  COMMIT;
  
  DBMS_OUTPUT.PUT_LINE('PR_SELL_BOND END');
  
END;