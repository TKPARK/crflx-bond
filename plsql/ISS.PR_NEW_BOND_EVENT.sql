CREATE OR REPLACE PROCEDURE ISS.PR_NEW_BOND_EVENT (
  I_BOND_TRADE IN OUT BOND_TRADE%ROWTYPE -- ROWTYPE : �ŷ����� TABLE
) IS
  --
  T_EVENT_INFO   EVENT_INFO_TYPE;        -- TYPE : EVENT_INFO_TYPE
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;   -- ROWTYPE : �ܰ� TABLE
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)�Է°� ����
  ----------------------------------------------------------------------------------------------------
  -- �ż��ܰ�
  IF I_BOND_TRADE.BUY_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '�ż��ܰ� ����');
  END IF;
  -- �Ÿż���
  IF I_BOND_TRADE.TRD_QTY <= 0 THEN
    PCZ_RAISE(-20999, '�Ÿż��� ����');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)�����ʱ�ȭ
  --   * Object���� �ʱ�ȭ �� Default������ ������
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO := FN_INIT_EVENT_INFO();
  T_BOND_BALANCE := FN_INIT_BOND_BALANCE();
  
  -- �ܰ�TABLE �Ϸù�ȣ ä��
  SELECT NVL(MAX(A.BALAN_SEQ), 0) + 1 AS BALAN_SEQ
    INTO I_BOND_TRADE.BALAN_SEQ
    FROM BOND_BALANCE A
   WHERE A.BIZ_DATE  = I_BOND_TRADE.BIZ_DATE
     AND A.FUND_CODE = I_BOND_TRADE.FUND_CODE
     AND A.BOND_CODE = I_BOND_TRADE.BOND_CODE
     AND A.BUY_DATE  = I_BOND_TRADE.BUY_DATE
     AND A.BUY_PRICE = I_BOND_TRADE.BUY_PRICE;

  -- �̺�Ʈ ��� TABLE SEQ ä��
--  SELECT NVL(MAX(A.EVENT_SEQ), 0) + 1 AS EVENT_SEQ
--    INTO I_BOND_TRADE.EVENT_SEQ
--    FROM EVENT_RESULT_NESTED_S A
--   WHERE A.FUND_CODE  = I_BOND_TRADE.FUND_CODE
--     AND A.BOND_CODE  = I_BOND_TRADE.BOND_CODE
--     AND A.BUY_DATE   = I_BOND_TRADE.BUY_DATE
--     AND A.BUY_PRICE  = I_BOND_TRADE.BUY_PRICE
--     AND A.BALAN_SEQ  = I_BOND_TRADE.BALAN_SEQ
--     AND A.EVENT_DATE = I_BOND_TRADE.EVENT_DATE;

  
  
  ----------------------------------------------------------------------------------------------------
  -- 3-1)INPUT ����
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := I_BOND_TRADE.FUND_CODE;           -- �ݵ��ڵ� (ä���ܰ��� PK)
  T_EVENT_INFO.BOND_CODE  := I_BOND_TRADE.BOND_CODE;           -- �����ڵ� (ä���ܰ��� PK)
  T_EVENT_INFO.BUY_DATE   := I_BOND_TRADE.BUY_DATE;            -- Buy Date (ä���ܰ��� PK)
  T_EVENT_INFO.BUY_PRICE  := I_BOND_TRADE.BUY_PRICE;           -- �ż��ܰ� (ä���ܰ��� PK)
  T_EVENT_INFO.BALAN_SEQ  := I_BOND_TRADE.BALAN_SEQ;           -- �ܰ��Ϸù�ȣ (ä���ܰ��� PK)
  T_EVENT_INFO.EVENT_DATE := I_BOND_TRADE.EVENT_DATE;          -- �̺�Ʈ�� (PK)
  T_EVENT_INFO.EVENT_SEQ  := I_BOND_TRADE.EVENT_SEQ;           -- �̺�ƮSEQ(PK)
  T_EVENT_INFO.EVENT_TYPE := I_BOND_TRADE.GOODS_BUY_SELL_SECT; -- Event ����
  T_EVENT_INFO.DL_UV      := I_BOND_TRADE.BUY_PRICE;           -- �ŷ��ܰ�
  T_EVENT_INFO.DL_QT      := I_BOND_TRADE.TRD_QTY;             -- �ŷ�����
  T_EVENT_INFO.STL_DT_TP  := I_BOND_TRADE.STT_TERM_SECT;       -- �����ϱ���
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
  I_BOND_TRADE.ACCRUED_INT  := T_EVENT_RESULT.ACCRUED_INT;                                -- �������
  I_BOND_TRADE.BOND_EIR     := T_EVENT_RESULT.EIR;                                        -- ��ȿ������
  I_BOND_TRADE.TRD_FACE_AMT := I_BOND_TRADE.TRD_QTY * 1000;                               -- �Ÿž׸�(���� * 1000)
  I_BOND_TRADE.TRD_AMT      := TRUNC(I_BOND_TRADE.BUY_PRICE * I_BOND_TRADE.TRD_QTY / 10); -- �Ÿűݾ�(���� * �ܰ� / 10)
  I_BOND_TRADE.TRD_NET_AMT  := I_BOND_TRADE.TRD_AMT-I_BOND_TRADE.ACCRUED_INT;             -- �Ÿ�����ݾ�(�Ÿűݾ� - �������)
  I_BOND_TRADE.BOOK_AMT     := I_BOND_TRADE.TRD_NET_AMT;                                  -- ��αݾ�
  I_BOND_TRADE.BOOK_PRC_AMT := I_BOND_TRADE.TRD_NET_AMT;                                  -- ��ο���
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5-1)�ŷ����� ���
  ----------------------------------------------------------------------------------------------------
  INSERT INTO ISS.BOND_TRADE VALUES I_BOND_TRADE;
  
  ----------------------------------------------------------------------------------------------------
  -- 5-2)�ܰ� ���
  ----------------------------------------------------------------------------------------------------
  INSERT INTO ISS.BOND_BALANCE VALUES T_BOND_BALANCE;
  
  
END;