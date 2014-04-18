 CREATE OR REPLACE PROCEDURE ISS.PR_CANCEL_BOND (
  I_CANCEL_INFO IN  CANCEL_INFO_TYPE       -- TYPE    : �������
, O_BOND_TRADE  OUT BOND_TRADE%ROWTYPE     -- ROWTYPE : �ŷ�����
) IS
  -- TYPE
  T_EVENT_INFO       EVENT_INFO_TYPE;      -- TYPE    : �̺�Ʈ INPUT
  T_BOND_BALANCE     BOND_BALANCE%ROWTYPE; -- ROWTYPE : �ܰ�
  T_ORGN_BOND_TRADE  BOND_TRADE%ROWTYPE;   -- ROWTYPE : ���ŷ�����
  
  -- CURSOR : ���ŷ�����
  CURSOR C_ORGN_BOND_TRADE_CUR IS
    SELECT *
      FROM BOND_TRADE
     WHERE TRD_DATE = I_CANCEL_INFO.TRD_DATE       -- �ŷ�����(�ŷ����� PK)
       AND TRD_SEQ  = I_CANCEL_INFO.TRD_SEQ;       -- �ŷ��Ϸù�ȣ(�ŷ����� PK)
  -- CURSOR : �ܰ�
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = T_ORGN_BOND_TRADE.TRD_DATE  -- �ŷ�����(�ܰ� PK)
       AND FUND_CODE = T_ORGN_BOND_TRADE.FUND_CODE -- �ݵ��ڵ�(�ܰ� PK)
       AND BOND_CODE = T_ORGN_BOND_TRADE.BOND_CODE -- �����ڵ�(�ܰ� PK)
       AND BUY_DATE  = T_ORGN_BOND_TRADE.BUY_DATE  -- �ż�����(�ܰ� PK)
       AND BUY_PRICE = T_ORGN_BOND_TRADE.BUY_PRICE -- �ż��ܰ�(�ܰ� PK)
       AND BALAN_SEQ = T_ORGN_BOND_TRADE.BALAN_SEQ -- �ܰ��Ϸù�ȣ(�ܰ� PK)
       FOR UPDATE;
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)�Է°� ����(INPUT �ʵ�)
  --   TRD_DATE   -- �ŷ�����(�ŷ����� PK)
  --   TRD_SEQ    -- �ŷ��Ϸù�ȣ(�ŷ����� PK)
  ----------------------------------------------------------------------------------------------------
  -- �ŷ�����
  IF I_CANCEL_INFO.TRD_DATE <> TO_CHAR(SYSDATE, 'YYYYMMDD') THEN
    RAISE_APPLICATION_ERROR(-20999, '�ŷ����� ����');
  END IF;
  -- �ŷ��Ϸù�ȣ
  IF I_CANCEL_INFO.TRD_SEQ <= 0 THEN
    RAISE_APPLICATION_ERROR(-20999, '�ŷ��Ϸù�ȣ ����');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)��Ҵ�� Ȯ��
  --   * ���ŷ����� ��ȸ
  --   * ��ҿ��� Ȯ��
  --   * ������ Ȯ��
  ----------------------------------------------------------------------------------------------------
  OPEN C_ORGN_BOND_TRADE_CUR;
    FETCH C_ORGN_BOND_TRADE_CUR INTO T_ORGN_BOND_TRADE;
    IF C_ORGN_BOND_TRADE_CUR%NOTFOUND THEN
      CLOSE C_ORGN_BOND_TRADE_CUR;
      RAISE_APPLICATION_ERROR(-20011, '���ŷ����� ����');
    END IF;
  CLOSE C_ORGN_BOND_TRADE_CUR;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3)�����ʱ�ȭ
  --   * Object���� �ʱ�ȭ �� Default������ ������
  ----------------------------------------------------------------------------------------------------
  PR_INIT_EVENT_INFO(T_EVENT_INFO);
  PR_INIT_BOND_TRADE(O_BOND_TRADE);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)��� ó�� ���ν��� ȣ��
  --   * INPUT ����
  --   * EVENT_RESULT ���̺� ���ŷ����� ����
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := T_ORGN_BOND_TRADE.FUND_CODE; -- �ݵ��ڵ�(�ܰ� PK)
  T_EVENT_INFO.BOND_CODE  := T_ORGN_BOND_TRADE.BOND_CODE; -- �����ڵ�(�ܰ� PK)
  T_EVENT_INFO.BUY_DATE   := T_ORGN_BOND_TRADE.BUY_DATE;  -- �ż�����(�ܰ� PK)
  T_EVENT_INFO.BUY_PRICE  := T_ORGN_BOND_TRADE.BUY_PRICE; -- �ż��ܰ�(�ܰ� PK)
  T_EVENT_INFO.BALAN_SEQ  := T_ORGN_BOND_TRADE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
  T_EVENT_INFO.EVENT_DATE := T_ORGN_BOND_TRADE.TRD_DATE;  -- �̺�Ʈ��
  T_EVENT_INFO.EVENT_SEQ  := T_ORGN_BOND_TRADE.EVENT_SEQ; -- �̺�Ʈ SEQ
  
  PKG_EIR_NESTED_NSC.PR_CANCEL_EVENT(T_EVENT_INFO);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5)�ܰ� ����
  --   * �ܰ� ��ȸ
  --   * 1.�ż� : �ܰ� ����
  --   * 2.�ŵ� : �ŵ��� �ܰ�� ����
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_BALANCE_CUR;
    FETCH C_BOND_BALANCE_CUR INTO T_BOND_BALANCE;
    IF C_BOND_BALANCE_CUR%NOTFOUND THEN
      CLOSE C_BOND_BALANCE_CUR;
      RAISE_APPLICATION_ERROR(-20011, '�ܰ� ����');
    END IF;
  CLOSE C_BOND_BALANCE_CUR;
  
  -- 1.�ż�
  IF T_ORGN_BOND_TRADE.GOODS_BUY_SELL_SECT = '1' THEN
    -- DELETE : �ܰ� ����
    DELETE FROM BOND_BALANCE
     WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- ��������(�ܰ� PK)
       AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
       AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- �����ڵ�(�ܰ� PK)
       AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- �ż�����(�ܰ� PK)
       AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
       AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
  
  -- 2.�ŵ�
  ELSIF T_ORGN_BOND_TRADE.GOODS_BUY_SELL_SECT = '2' THEN
    /* �ŵ��� �ܰ�� ���� */
    
    -- �ܰ���� RULE //
    IF T_ORGN_BOND_TRADE.STT_TERM_SECT = '1' THEN
      T_BOND_BALANCE.TOT_QTY       := T_BOND_BALANCE.TOT_QTY + T_ORGN_BOND_TRADE.TRD_QTY;                                             -- ���ܰ����
      T_BOND_BALANCE.TDY_AVAL_QTY  := T_BOND_BALANCE.TDY_AVAL_QTY + T_ORGN_BOND_TRADE.TRD_QTY;                                        -- ���ϰ������
      T_BOND_BALANCE.NDY_AVAL_QTY  := T_BOND_BALANCE.NDY_AVAL_QTY + T_ORGN_BOND_TRADE.TRD_QTY;                                        -- ���ϰ������
    ELSIF T_ORGN_BOND_TRADE.STT_TERM_SECT = '2' THEN
      T_BOND_BALANCE.TOT_QTY       := T_BOND_BALANCE.TOT_QTY + T_ORGN_BOND_TRADE.TRD_QTY;                                             -- ���ܰ����
      T_BOND_BALANCE.TDY_AVAL_QTY  := T_BOND_BALANCE.TDY_AVAL_QTY;                                                                    -- ���ϰ������
      T_BOND_BALANCE.NDY_AVAL_QTY  := T_BOND_BALANCE.NDY_AVAL_QTY + T_ORGN_BOND_TRADE.TRD_QTY;                                        -- ���ϰ������
    END IF;
    -- // END
    
    T_BOND_BALANCE.BOOK_AMT        := (T_BOND_BALANCE.BOOK_AMT - T_ORGN_BOND_TRADE.SANGGAK_AMT) + T_ORGN_BOND_TRADE.BOOK_AMT;         -- ��αݾ�
    T_BOND_BALANCE.BOOK_PRC_AMT    := (T_BOND_BALANCE.BOOK_PRC_AMT - T_ORGN_BOND_TRADE.SANGGAK_AMT) + T_ORGN_BOND_TRADE.BOOK_PRC_AMT; -- ��ο���
    T_BOND_BALANCE.ACCRUED_INT     := T_BOND_BALANCE.ACCRUED_INT + T_ORGN_BOND_TRADE.ACCRUED_INT;                                     -- �������
    T_BOND_BALANCE.BTRM_UNPAID_INT := T_BOND_BALANCE.BTRM_UNPAID_INT + T_ORGN_BOND_TRADE.BTRM_UNPAID_INT;                             -- ����̼�����
    T_BOND_BALANCE.TTRM_BOND_INT   := T_BOND_BALANCE.TTRM_BOND_INT + T_ORGN_BOND_TRADE.BTRM_UNPAID_INT;                               -- ���ä������
    T_BOND_BALANCE.SANGGAK_AMT     := T_BOND_BALANCE.SANGGAK_AMT - T_ORGN_BOND_TRADE.SANGGAK_AMT;                                     -- �󰢱ݾ�
    T_BOND_BALANCE.MI_SANGGAK_AMT  := T_BOND_BALANCE.MI_SANGGAK_AMT + T_BOND_BALANCE.SANGGAK_AMT;                                     -- �̻󰢱ݾ�(�ܰ�.�̻󰢱ݾ�-�󰢱ݾ�)
    T_BOND_BALANCE.TRD_PRFT        := T_BOND_BALANCE.TRD_PRFT - T_ORGN_BOND_TRADE.TRD_PRFT;                                           -- �Ÿ�����
    T_BOND_BALANCE.TRD_LOSS        := T_BOND_BALANCE.TRD_LOSS - T_ORGN_BOND_TRADE.TRD_LOSS;                                           -- �Ÿżս�
    T_BOND_BALANCE.TXSTD_AMT       := T_BOND_BALANCE.TXSTD_AMT - T_ORGN_BOND_TRADE.TXSTD_AMT;                                         -- ��ǥ�ݾ�
    T_BOND_BALANCE.CORP_TAX        := T_BOND_BALANCE.CORP_TAX - T_ORGN_BOND_TRADE.CORP_TAX;                                           -- ���޹��μ�
    T_BOND_BALANCE.UNPAID_CORP_TAX := T_BOND_BALANCE.UNPAID_CORP_TAX - T_ORGN_BOND_TRADE.UNPAID_CORP_TAX;                             -- �����޹��μ�
    
    -- UPDATE : �ܰ� ����
    UPDATE BOND_BALANCE 
       SET ROW = T_BOND_BALANCE
     WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- ��������(�ܰ� PK)
       AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
       AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- �����ڵ�(�ܰ� PK)
       AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- �ż�����(�ܰ� PK)
       AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
       AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 6)���ŷ����� ���ó��
  --   * ��ҿ��� �ʵ尪 ����
  ----------------------------------------------------------------------------------------------------
  T_ORGN_BOND_TRADE.CANCEL_YN := 'Y'; -- ��ҿ���
  
  -- UPDATE : ���ó��
  UPDATE BOND_TRADE 
     SET ROW = T_ORGN_BOND_TRADE
   WHERE TRD_DATE = T_ORGN_BOND_TRADE.TRD_DATE -- �ŷ�����(�ŷ����� PK)
     AND TRD_SEQ  = T_ORGN_BOND_TRADE.TRD_SEQ; -- �ŷ��Ϸù�ȣ(�ŷ����� PK)
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 7)��Ұŷ����� ���
  ----------------------------------------------------------------------------------------------------
  O_BOND_TRADE.TRD_DATE   := I_CANCEL_INFO.TRD_DATE;    -- �ŷ�����(PK)
  
  -- �ŷ��Ϸù�ȣ ä�� RULE //
  SELECT NVL(MAX(TRD_SEQ), 0) + 1 AS TRD_SEQ
    INTO O_BOND_TRADE.TRD_SEQ                           -- �ŷ��Ϸù�ȣ(PK)
    FROM BOND_TRADE
   WHERE TRD_DATE = I_CANCEL_INFO.TRD_DATE;
  -- // END
  
  O_BOND_TRADE.FUND_CODE  := T_BOND_BALANCE.FUND_CODE;  -- �ݵ��ڵ�
  O_BOND_TRADE.BOND_CODE  := T_BOND_BALANCE.BOND_CODE;  -- �����ڵ�
  O_BOND_TRADE.BUY_DATE   := T_BOND_BALANCE.BUY_DATE;   -- �ż�����
  O_BOND_TRADE.BUY_PRICE  := T_BOND_BALANCE.BUY_PRICE;  -- �ż��ܰ�
  O_BOND_TRADE.BALAN_SEQ  := T_BOND_BALANCE.BALAN_SEQ;  -- �ܰ��Ϸù�ȣ
  
  --O_BOND_TRADE.EVENT_DATE := T_EVENT_RESULT.EVENT_DATE; -- �̺�Ʈ��
  --O_BOND_TRADE.EVENT_SEQ  := T_EVENT_RESULT.EVENT_SEQ;  -- �̺�Ʈ SEQ
  
  
  -- INSERT : �ŷ����� ���
  INSERT INTO BOND_TRADE VALUES O_BOND_TRADE;
  
  
  
  DBMS_OUTPUT.PUT_LINE('PR_CANCEL_BOND END');
  
END;