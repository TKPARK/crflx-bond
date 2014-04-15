CREATE OR REPLACE PROCEDURE ISS.PR_BUY_BOND (
  I_BUY_INFO   IN  BUY_INFO_TYPE_S                   -- TYPE    : �ż�����
, O_BOND_TRADE OUT BOND_TRADE%ROWTYPE                -- ROWTYPE : �ŷ�����
) IS
  -- TYPE
  T_EVENT_INFO   PKG_EIR_NESTED_NSC.EVENT_INFO_TYPE; -- TYPE    : �̺�Ʈ INPUT
  T_EVENT_RESULT EVENT_RESULT_NESTED_S%ROWTYPE;      -- ROWTYPE : �̺�Ʈ OUTPUT
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;               -- ROWTYPE : �ܰ�
  T_BOND_INFO    BOND_INFO%ROWTYPE;                  -- ROWTYPE : ����
  
  -- CURSOR : ����
  CURSOR C_BOND_INFO_CUR IS
    SELECT *
      FROM BOND_INFO
     WHERE BOND_CODE = I_BUY_INFO.BOND_CODE;
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)�Է°� ����(INPUT �ʵ�)
  --   TRD_DATE   -- �ŷ�����
  --   FUND_CODE  -- �ݵ��ڵ�
  --   BOND_CODE  -- �����ڵ�
  --   BUY_PRICE  -- �ż��ܰ�
  --   BUY_QTY    -- �ż�����
  --   BOND_IR    -- ǥ��������
  --   STL_DT_TP  -- �����ϱ���(1.����, 2.����)
  ----------------------------------------------------------------------------------------------------
  -- �ż��ܰ�
  IF I_BUY_INFO.BUY_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '�ż��ܰ� ����');
  END IF;
  -- �ż�����
  IF I_BUY_INFO.BUY_QTY <= 0 THEN
    PCZ_RAISE(-20999, '�ż����� ����');
  END IF;
  -- ǥ��������
  IF I_BUY_INFO.BOND_IR <= 0 THEN
    PCZ_RAISE(-20999, 'ǥ�������� ����');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)���� Ȯ��
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_INFO_CUR;
  FETCH C_BOND_INFO_CUR INTO T_BOND_INFO;
  IF C_BOND_INFO_CUR%NOTFOUND THEN
    CLOSE C_BOND_INFO_CUR;
    RAISE_APPLICATION_ERROR(-20011, '���� ����');
  END IF;
  CLOSE C_BOND_INFO_CUR;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3)�����ʱ�ȭ
  --   * Object���� �ʱ�ȭ �� Default������ ������
  --   * �ܰ� TABLE SEQ ä��
  ----------------------------------------------------------------------------------------------------
  --T_EVENT_INFO   := PKG_EIR_NESTED_NSC.FN_INIT_EVENT_INFO();
  T_EVENT_RESULT := FN_INIT_EVENT_RESULT();
  O_BOND_TRADE   := FN_INIT_BOND_TRADE();
  T_BOND_BALANCE := FN_INIT_BOND_BALANCE();
  T_BOND_INFO    := FN_INIT_BOND_INFO();  
  
  -- �ܰ��Ϸù�ȣ ä��
  SELECT NVL(MAX(BALAN_SEQ), 0) + 1 AS BALAN_SEQ
    INTO O_BOND_TRADE.BALAN_SEQ
    FROM BOND_BALANCE
   WHERE BIZ_DATE  = I_BUY_INFO.TRD_DATE
     AND FUND_CODE = I_BUY_INFO.FUND_CODE
     AND BOND_CODE = I_BUY_INFO.BOND_CODE
     AND BUY_DATE  = I_BUY_INFO.TRD_DATE
     AND BUY_PRICE = I_BUY_INFO.BUY_PRICE;
  
  -- �������� RULE //
  -- 1.���� : �������� = �ż�����
  -- 2.���� : �������� = ������ ��� ���� ó��
  IF I_BUY_INFO.STL_DT_TP = '1' THEN
    O_BOND_TRADE.SETL_DATE := I_BUY_INFO.TRD_DATE;
  ELSIF I_BUY_INFO.STL_DT_TP = '2' THEN
    -- ������ ��� ���� ó��
    O_BOND_TRADE.SETL_DATE := TO_CHAR(TO_DATE(I_BUY_INFO.TRD_DATE, 'YYYYMMDD')+1, 'YYYYMMDD');
  END IF;
  -- // END
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)�ż� ó�� ���ν��� ȣ��
  --   * INPUT ����
  --   * �������, �����帧 ����, EIR����, ��ǥ ���� ó��
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := I_BUY_INFO.FUND_CODE;   -- �ݵ��ڵ�(�ܰ� PK)
  T_EVENT_INFO.BOND_CODE  := I_BUY_INFO.BOND_CODE;   -- �����ڵ�(�ܰ� PK)
  T_EVENT_INFO.BUY_DATE   := O_BOND_TRADE.SETL_DATE; -- �ż�����(�ܰ� PK)
  T_EVENT_INFO.BUY_PRICE  := I_BUY_INFO.BUY_PRICE;   -- �ż��ܰ�(�ܰ� PK)
  T_EVENT_INFO.BALAN_SEQ  := O_BOND_TRADE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
  T_EVENT_INFO.EVENT_DATE := O_BOND_TRADE.SETL_DATE; -- �̺�Ʈ��
  T_EVENT_INFO.EVENT_TYPE := '1';                    -- Event����(1.�ż�, 2.�ŵ�(��ȯ), 3.�ݸ�����, 4.�ջ�)
  T_EVENT_INFO.DL_UV      := I_BUY_INFO.BUY_PRICE;   -- �ŷ��ܰ�
  T_EVENT_INFO.DL_QT      := I_BUY_INFO.BUY_QTY;     -- �ŷ�����
  T_EVENT_INFO.IR         := I_BUY_INFO.BOND_IR;     -- ǥ��������
  
  PKG_EIR_NESTED_NSC.PR_NEW_BUY_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5)�ŷ����� ���(�������� ���)
  --   * T_EVENT_RESULT �����͸� ������ �������� ����
  --   * ���������� �ʿ��� ��ȸ �� ��� ���� ���� ����
  ----------------------------------------------------------------------------------------------------
  O_BOND_TRADE.TRD_DATE            := I_BUY_INFO.TRD_DATE;                                   -- �ŷ�����(PK)
  
  -- �ŷ��Ϸù�ȣ ä�� RULE //
  SELECT NVL(MAX(TRD_SEQ), 0) + 1 AS TRD_SEQ
    INTO O_BOND_TRADE.TRD_SEQ                                                                -- �ŷ��Ϸù�ȣ(PK)
    FROM BOND_TRADE
   WHERE TRD_DATE = I_BUY_INFO.TRD_DATE;
  -- // END
  
  O_BOND_TRADE.FUND_CODE           := I_BUY_INFO.FUND_CODE;                                  -- �ݵ��ڵ�
  O_BOND_TRADE.BOND_CODE           := I_BUY_INFO.BOND_CODE;                                  -- �����ڵ�
  O_BOND_TRADE.BUY_DATE            := I_BUY_INFO.TRD_DATE;                                   -- �ż�����
  O_BOND_TRADE.BUY_PRICE           := I_BUY_INFO.BUY_PRICE;                                  -- �ż��ܰ�
  O_BOND_TRADE.TRD_TYPE_CD         := '2';                                                   -- �Ÿ������ڵ�(1.�μ�,2.���ż�,3.���ŵ�,4.��ȯ)
  O_BOND_TRADE.GOODS_BUY_SELL_SECT := '1';                                                   -- ��ǰ�ż��ŵ�����(1.��ǰ�ż�,2.��ǰ�ŵ�)
  O_BOND_TRADE.STT_TERM_SECT       := I_BUY_INFO.STL_DT_TP;                                  -- �����Ⱓ����(0.����,1.����)
  
  
  O_BOND_TRADE.EXPR_DATE           := T_BOND_INFO.EXPIRE_DATE;                               -- ��������
  O_BOND_TRADE.EVENT_DATE          := T_EVENT_RESULT.EVENT_DATE;                             -- �̺�Ʈ��
  O_BOND_TRADE.EVENT_SEQ           := T_EVENT_RESULT.EVENT_SEQ;                              -- �̺�Ʈ SEQ
  O_BOND_TRADE.TRD_PRICE           := I_BUY_INFO.BUY_PRICE;                                  -- �ŸŴܰ�
  O_BOND_TRADE.TRD_QTY             := I_BUY_INFO.BUY_QTY;                                    -- �Ÿż���
  O_BOND_TRADE.BOND_EIR            := T_EVENT_RESULT.EIR;                                    -- ��ȿ������
  O_BOND_TRADE.BOND_IR             := I_BUY_INFO.BOND_IR;                                    -- ǥ��������
  O_BOND_TRADE.TOT_INT             := T_EVENT_RESULT.ACCRUED_INT;                            -- �����ڱݾ�(�ż������̹Ƿ� �����ڴ� �������)
  O_BOND_TRADE.ACCRUED_INT         := T_EVENT_RESULT.ACCRUED_INT;                            -- �������
  O_BOND_TRADE.TRD_FACE_AMT        := I_BUY_INFO.BUY_QTY * 1000;                             -- �Ÿž׸�(���� * 1000)
  O_BOND_TRADE.TRD_AMT             := TRUNC(I_BUY_INFO.BUY_PRICE * I_BUY_INFO.BUY_QTY / 10); -- �Ÿűݾ�(���� * �ܰ� / 10)
  O_BOND_TRADE.TRD_NET_AMT         := O_BOND_TRADE.TRD_AMT - T_EVENT_RESULT.ACCRUED_INT;     -- �Ÿ�����ݾ�(�Ÿűݾ� - �������)
  O_BOND_TRADE.BOOK_AMT            := O_BOND_TRADE.TRD_NET_AMT;                              -- ��αݾ�
  O_BOND_TRADE.BOOK_PRC_AMT        := O_BOND_TRADE.TRD_NET_AMT;                              -- ��ο���
  
  -- INSERT : �ŷ����� ���
  INSERT INTO BOND_TRADE VALUES O_BOND_TRADE;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 6)�ܰ� ���
  ----------------------------------------------------------------------------------------------------
  T_BOND_BALANCE.BIZ_DATE       := O_BOND_TRADE.TRD_DATE;         -- ��������(PK)
  T_BOND_BALANCE.FUND_CODE      := O_BOND_TRADE.FUND_CODE;        -- �ݵ��ڵ�(PK)
  T_BOND_BALANCE.BOND_CODE      := O_BOND_TRADE.BOND_CODE;        -- �����ڵ�(PK)
  T_BOND_BALANCE.BUY_DATE       := O_BOND_TRADE.BUY_DATE;         -- �ż�����(PK)
  T_BOND_BALANCE.BUY_PRICE      := O_BOND_TRADE.BUY_PRICE;        -- �ż��ܰ�(PK)
  T_BOND_BALANCE.BALAN_SEQ      := O_BOND_TRADE.BALAN_SEQ;        -- �ܰ��Ϸù�ȣ(PK)
  T_BOND_BALANCE.BOND_IR        := O_BOND_TRADE.BOND_IR;          -- IR
  T_BOND_BALANCE.BOND_EIR       := O_BOND_TRADE.BOND_EIR;         -- EIR
  
  -- �ܰ���� RULE //
  -- 1.����(�ż� 100)
  --   ex)���ܰ���� = 100, �����ܰ���� = 100, �����ܰ���� = 100;
  -- 2.����(�ż� 100)
  --   ex)���ܰ���� = 100, �����ܰ���� =   0, �����ܰ���� = 100;
  IF O_BOND_TRADE.STT_TERM_SECT = '1' THEN
    T_BOND_BALANCE.TOT_QTY        := O_BOND_TRADE.TRD_QTY;        -- ���ܰ����
    T_BOND_BALANCE.TDY_AVAL_QTY   := O_BOND_TRADE.TRD_QTY;        -- ���ϰ������
    T_BOND_BALANCE.NDY_AVAL_QTY   := O_BOND_TRADE.TRD_QTY;        -- ���ϰ������
  ELSIF O_BOND_TRADE.STT_TERM_SECT = '2' THEN
    T_BOND_BALANCE.TOT_QTY        := O_BOND_TRADE.TRD_QTY;        -- ���ܰ����
    T_BOND_BALANCE.TDY_AVAL_QTY   := 0;                           -- ���ϰ������
    T_BOND_BALANCE.NDY_AVAL_QTY   := O_BOND_TRADE.TRD_QTY;        -- ���ϰ������
  END IF;
  -- // END
  
  T_BOND_BALANCE.BOOK_AMT       := O_BOND_TRADE.BOOK_AMT;         -- ��αݾ�
  T_BOND_BALANCE.BOOK_PRC_AMT   := O_BOND_TRADE.BOOK_PRC_AMT;     -- ��ο���
  T_BOND_BALANCE.ACCRUED_INT    := O_BOND_TRADE.ACCRUED_INT;      -- �������
  T_BOND_BALANCE.MI_SANGGAK_AMT := T_EVENT_RESULT.MI_SANGGAK_AMT; -- �̻󰢱ݾ�(�̻�����)
  T_BOND_BALANCE.DRT_BUY_QTY    := O_BOND_TRADE.TRD_QTY;          -- ���ż�����
  
  -- INSERT : �ܰ� ���
  INSERT INTO BOND_BALANCE VALUES T_BOND_BALANCE;
  
  
  
  DBMS_OUTPUT.PUT_LINE('PR_BUY_BOND END');
  
END;