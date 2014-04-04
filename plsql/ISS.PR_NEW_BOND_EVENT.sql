CREATE OR REPLACE PROCEDURE ISS.PR_NEW_BOND_EVENT (
  -- �ŷ�����ROWTPYE�� I/O�� ���(���� <-> ���ν���)
  I_BOND_TRADE IN OUT BOND_TRADE%ROWTYPE -- ROWTYPE : �ŷ�����
) IS
  --
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;   -- ROWTYPE : �ܰ�
  T_EVENT_INFO   EVENT_INFO_TYPE;        -- TYPE : EVENT_INFO_TYPE
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)�Է°� ����(INPUT �ʵ�)
  --   TRD_DATE            -- �ŷ�����(PK)
  --   FUND_CODE           -- �ݵ��ڵ�
  --   BOND_CODE           -- �����ڵ�
  --   BUY_DATE            -- �ż�����
  --   BUY_PRICE           -- �ż��ܰ�
  --   TRD_TYPE_CD         -- �Ÿ������ڵ�(1.�μ�, 2.���ż�, 3.���ŵ�, 4.��ȯ)
  --   GOODS_BUY_SELL_SECT -- ��ǰ�ż��ŵ�����(1.�ż�, 2.�ŵ�, 3.�ݸ�����, 4.�ջ�, 5.ȸ��)
  --   STT_TERM_SECT       -- �����Ⱓ����(1.����, 2.����)
  --   TRD_PRICE           -- �ŸŴܰ�
  --   TRD_QTY             -- �Ÿż���
  --   BOND_IR             -- ǥ��������
  ----------------------------------------------------------------------------------------------------
  -- �ŸŴܰ�
  IF I_BOND_TRADE.TRD_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '�ŸŴܰ� ����');
  END IF;
  -- �Ÿż���
  IF I_BOND_TRADE.TRD_QTY <= 0 THEN
    PCZ_RAISE(-20999, '�Ÿż��� ����');
  END IF;
  -- ǥ��������
  IF I_BOND_TRADE.BOND_IR <= 0 THEN
    PCZ_RAISE(-20999, 'ǥ�������� ����');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)�����ʱ�ȭ
  --   * Object���� �ʱ�ȭ �� Default������ ������
  --   * �ŷ�����, �ܰ� TABLE SEQ ä��
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO := FN_INIT_EVENT_INFO();
  T_BOND_BALANCE := FN_INIT_BOND_BALANCE();
  
  -- �ŷ����� �ŷ��Ϸù�ȣ(PK) ä��
  SELECT NVL(MAX(A.TRD_SEQ), 0) + 1 AS TRD_SEQ
    INTO I_BOND_TRADE.TRD_SEQ
    FROM BOND_TRADE A
   WHERE A.TRD_DATE  = I_BOND_TRADE.TRD_DATE;
  
  -- �ܰ� �ܰ��Ϸù�ȣ(PK) ä��
  SELECT NVL(MAX(A.BALAN_SEQ), 0) + 1 AS BALAN_SEQ
    INTO I_BOND_TRADE.BALAN_SEQ
    FROM BOND_BALANCE A
   WHERE A.BIZ_DATE  = I_BOND_TRADE.TRD_DATE
     AND A.FUND_CODE = I_BOND_TRADE.FUND_CODE
     AND A.BOND_CODE = I_BOND_TRADE.BOND_CODE
     AND A.BUY_DATE  = I_BOND_TRADE.BUY_DATE
     AND A.BUY_PRICE = I_BOND_TRADE.BUY_PRICE;
  
  -- �������� RULE
  -- 1.���� : �������� = �ż�����
  -- 2.���� : �������� = �ż����� + 1��
  IF I_BOND_TRADE.STT_TERM_SECT = '1' THEN
    I_BOND_TRADE.SETL_DATE    := I_BOND_TRADE.BUY_DATE; -- ��������
  ELSIF I_BOND_TRADE.STT_TERM_SECT = '2' THEN
    I_BOND_TRADE.SETL_DATE    := TO_CHAR(TO_DATE(I_BOND_TRADE.BUY_DATE, 'YYYYMMDD')+1), 'YYYYMMDD'); -- ��������
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3-1)INPUT ����
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := I_BOND_TRADE.FUND_CODE;           -- �ݵ��ڵ�(ä���ܰ��� PK)
  T_EVENT_INFO.BOND_CODE  := I_BOND_TRADE.BOND_CODE;           -- �����ڵ�(ä���ܰ��� PK)
  T_EVENT_INFO.BUY_DATE   := I_BOND_TRADE.BUY_DATE;            -- Buy Date(ä���ܰ��� PK)
  T_EVENT_INFO.BUY_PRICE  := I_BOND_TRADE.BUY_PRICE;           -- �ż��ܰ�(ä���ܰ��� PK)
  T_EVENT_INFO.BALAN_SEQ  := I_BOND_TRADE.BALAN_SEQ;           -- �ܰ��Ϸù�ȣ(ä���ܰ��� PK)
  T_EVENT_INFO.EVENT_DATE := I_BOND_TRADE.SETL_DATE;           -- �̺�Ʈ��(PK)
  T_EVENT_INFO.EVENT_TYPE := I_BOND_TRADE.GOODS_BUY_SELL_SECT; -- Event ����(1.�ż�, 2.�ŵ�, 3.�ݸ�����, 4.�ջ�, 5.ȸ��)
  T_EVENT_INFO.DL_UV      := I_BOND_TRADE.BUY_PRICE;           -- �ŷ��ܰ�
  T_EVENT_INFO.DL_QT      := I_BOND_TRADE.TRD_QTY;             -- �ŷ�����
  T_EVENT_INFO.STL_DT_TP  := I_BOND_TRADE.STT_TERM_SECT;       -- �����ϱ���(1.����, 2.����)
  T_EVENT_INFO.IR         := I_BOND_TRADE.BOND_IR;             -- ǥ��������
  
  ----------------------------------------------------------------------------------------------------
  -- 3-2)���� �ż� �̺�Ʈ ó�� ���ν��� ȣ��
  --   * �������, �����帧 ����, EIR����, ��ǥ ���� ó��
  ----------------------------------------------------------------------------------------------------
  PKG_EIR_NESTED_NSC.PR_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)�������� ���
  --   * T_EVENT_RESULT �����͸� ������ �������� ����
  --   * ���������� �ʿ��� ��ȸ �� ��� ���� ���� ����
  ----------------------------------------------------------------------------------------------------
  I_BOND_TRADE.TOT_INT      := T_EVENT_RESULT.ACCRUED_INT;                                -- �����ڱݾ�
  I_BOND_TRADE.ACCRUED_INT  := T_EVENT_RESULT.ACCRUED_INT;                                -- �������
  I_BOND_TRADE.EXPR_DATE    := ; -- ��������
  I_BOND_TRADE.BOND_EIR     := T_EVENT_RESULT.EIR;                                        -- ��ȿ������
  I_BOND_TRADE.TRD_FACE_AMT := I_BOND_TRADE.TRD_QTY * 1000;                               -- �Ÿž׸�(���� * 1000)
  I_BOND_TRADE.TRD_AMT      := TRUNC(I_BOND_TRADE.TRD_PRICE * I_BOND_TRADE.TRD_QTY / 10); -- �Ÿűݾ�(���� * �ܰ� / 10)
  I_BOND_TRADE.TRD_NET_AMT  := I_BOND_TRADE.TRD_AMT-I_BOND_TRADE.ACCRUED_INT;             -- �Ÿ�����ݾ�(�Ÿűݾ� - �������)
  I_BOND_TRADE.BOOK_AMT     := I_BOND_TRADE.TRD_NET_AMT;                                  -- ��αݾ�
  I_BOND_TRADE.BOOK_PRC_AMT := I_BOND_TRADE.TRD_NET_AMT;                                  -- ��ο���
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5-1)�ŷ����� ���
  ----------------------------------------------------------------------------------------------------
  INSERT INTO BOND_TRADE VALUES I_BOND_TRADE;
  
  ----------------------------------------------------------------------------------------------------
  -- 5-2)�ܰ� ���
  ----------------------------------------------------------------------------------------------------
  -- PK
  T_BOND_BALANCE.BIZ_DATE       := T_BOND_TRADE.TRD_DATE;         -- ��������(PK)
  T_BOND_BALANCE.FUND_CODE      := T_BOND_TRADE.FUND_CODE;        -- �ݵ��ڵ�(PK)
  T_BOND_BALANCE.BOND_CODE      := T_BOND_TRADE.BOND_CODE;        -- �����ڵ�(PK)
  T_BOND_BALANCE.BUY_DATE       := T_BOND_TRADE.BUY_DATE;         -- �ż�����(PK)
  T_BOND_BALANCE.BUY_PRICE      := T_BOND_TRADE.BUY_PRICE;        -- �ż��ܰ�(PK)
  T_BOND_BALANCE.BALAN_SEQ      := T_BOND_TRADE.BALAN_SEQ;        -- �ܰ��Ϸù�ȣ(PK)
  
  -- VALUE
  T_BOND_BALANCE.BOND_IR        := T_BOND_TRADE.BOND_IR;          -- IR
  T_BOND_BALANCE.BOND_EIR       := T_BOND_TRADE.BOND_EIR;         -- EIR
  
  -- �ܰ���� RULE
  -- 1.����(�ż� 100)
  --   ex)���ܰ���� = 100, �����ܰ���� = 100, �����ܰ���� = 100;
  -- 2.����(�ż� 100)
  --   ex)���ܰ���� = 100, �����ܰ���� =   0, �����ܰ���� = 100;
  IF I_BOND_TRADE.STT_TERM_SECT = '1' THEN
    T_BOND_BALANCE.TOT_QTY        := T_BOND_TRADE.TRD_QTY;        -- ���ܰ����
    T_BOND_BALANCE.TDY_AVAL_QTY   := T_BOND_TRADE.TRD_QTY;        -- ���ϰ������
    T_BOND_BALANCE.NDY_AVAL_QTY   := T_BOND_TRADE.TRD_QTY;        -- ���ϰ������
  ELSIF I_BOND_TRADE.STT_TERM_SECT = '2' THEN
    T_BOND_BALANCE.TOT_QTY        := T_BOND_TRADE.TRD_QTY;        -- ���ܰ����
    T_BOND_BALANCE.TDY_AVAL_QTY   := 0;                           -- ���ϰ������
    T_BOND_BALANCE.NDY_AVAL_QTY   := T_BOND_TRADE.TRD_QTY;        -- ���ϰ������
  END IF;
  T_BOND_BALANCE.BOOK_AMT       := T_BOND_TRADE.BOOK_AMT;         -- ��αݾ�
  T_BOND_BALANCE.BOOK_PRC_AMT   := T_BOND_TRADE.BOOK_PRC_AMT;     -- ��ο���
  T_BOND_BALANCE.ACCRUED_INT    := T_BOND_TRADE.ACCRUED_INT;      -- �������
  T_BOND_BALANCE.MI_SANGGAK_AMT := T_EVENT_RESULT.MI_SANGGAK_AMT; -- �̻󰢱ݾ�(�̻�����)
  T_BOND_BALANCE.DRT_BUY_QTY    := T_BOND_TRADE.TRD_QTY;          -- ���ż�����

  INSERT INTO BOND_BALANCE VALUES T_BOND_BALANCE;
  
  
END;