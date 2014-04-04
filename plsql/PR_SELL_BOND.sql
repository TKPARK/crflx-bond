CREATE OR REPLACE PROCEDURE ISS.PR_SELL_BOND (
  I_SELL_INFO  IN  SELL_INFO_TYPE_S               -- TYPE    : �ŵ�����
, O_BOND_TRADE OUT BOND_TRADE%ROWTYPE             -- ROWTYPE : �ŷ�����
) IS
  --
  T_EVENT_INFO     EVENT_INFO_TYPE;               -- TYPE    : �ŵ��̺�Ʈ INPUT
  T_EVENT_RESULT   EVENT_RESULT_NESTED_S%ROWTYPE; -- ROWTYPE : �ż��̺�Ʈ OUTPUT
  T_BOND_BALANCE   BOND_BALANCE%ROWTYPE;          -- ROWTYPE : �ܰ�
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)�ܰ�Ȯ��
  --   * �ܰ�TABLE�� ��ȸ�Ͽ� �ܰ� ���� Ȯ��
  ----------------------------------------------------------------------------------------------------
  FOR C1 IN (SELECT *
               FROM BOND_BALANCE
              WHERE BIZ_DATE  = I_SELL_INFO.BIZ_DATE   -- ��������(�ܰ� PK)
                AND FUND_CODE = I_SELL_INFO.FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
                AND BOND_CODE = I_SELL_INFO.BOND_CODE  -- �����ڵ�(�ܰ� PK)
                AND BUY_DATE  = I_SELL_INFO.BUY_DATE   -- �ż�����(�ܰ� PK)
                AND BUY_PRICE = I_SELL_INFO.BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
                AND BALAN_SEQ = I_SELL_INFO.BALAN_SEQ) -- �ܰ��Ϸù�ȣ(�ܰ� PK)
  LOOP
    T_BOND_BALANCE := C1;
    EXIT;
  END LOOP;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)�Է°� ����(INPUT �ʵ�)
  --   SELL_DATE  -- �ŵ�����
  --   SELL_PRICE -- �ŵ��ܰ�
  --   SELL_QTY   -- �ŵ�����
  ----------------------------------------------------------------------------------------------------
  -- �ŵ�����
  IF I_SELL_INFO.SELL_DATE = '' THEN
    PCZ_RAISE(-20999, '�ŵ����� ����');
  END IF;
  -- �ŵ��ܰ�
  IF I_SELL_INFO.SELL_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '�ŵ��ܰ� ����');
  END IF;
  -- �ŵ�����
  IF I_SELL_INFO.SELL_QTY <= 0 THEN
    PCZ_RAISE(-20999, '�ŵ����� ����');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3)�����ʱ�ȭ
  --   * Object���� �ʱ�ȭ �� Default������ ������
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO   := FN_INIT_EVENT_INFO();
  T_EVENT_RESULT := FN_INIT_EVENT_RESULT();
  O_BOND_TRADE   := FN_INIT_BOND_TRADE();
  
  -- �������� RULE
  -- 1.���� : �������� = �ŵ�����
  -- 2.���� : �������� = �ŵ����� + 1��
  IF I_SELL_INFO.STT_TERM_SECT = '1' THEN
    O_BOND_TRADE.SETL_DATE    := I_SELL_INFO.SELL_DATE;
  ELSIF I_SELL_INFO.STT_TERM_SECT = '2' THEN
    O_BOND_TRADE.SETL_DATE    := TO_CHAR(TO_DATE(I_SELL_INFO.SELL_DATE, 'YYYYMMDD')+1), 'YYYYMMDD');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)�ŵ� �̺�Ʈ ó�� ���ν��� ȣ��
  --   * INPUT ����
  --   * �󰢱ݾ׻���, ��ǥ �����, ������, ��αݾ׻���
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := T_BOND_BALANCE.FUND_CODE; -- �ݵ��ڵ�(ä���ܰ���PK)
  T_EVENT_INFO.BOND_CODE  := T_BOND_BALANCE.BOND_CODE; -- �����ڵ�(ä���ܰ���PK)
  T_EVENT_INFO.BUY_DATE   := T_BOND_BALANCE.TRD_DATE;  -- �ż�����(ä���ܰ���PK)
  T_EVENT_INFO.BUY_PRICE  := T_BOND_BALANCE.BUY_PRICE; -- �ż��ܰ�(ä���ܰ���PK)
  T_EVENT_INFO.BALAN_SEQ  := T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(ä���ܰ���PK)
  T_EVENT_INFO.EVENT_DATE := O_BOND_TRADE.SETL_DATE;   -- �̺�Ʈ��
  T_EVENT_INFO.EVENT_TYPE := I_SELL_INFO.EVENT_TYPE;   -- Event����(1.�ż�,2.�ŵ�,3.�ݸ�����,4.�ջ�,5.ȸ��)
  T_EVENT_INFO.DL_UV      := I_SELL_INFO.BUY_PRICE;    -- �ŷ��ܰ�
  T_EVENT_INFO.DL_QT      := I_SELL_INFO.BUY_QTY;      -- �ŷ�����
  T_EVENT_INFO.STL_DT_TP  := I_SELL_INFO.STL_DT_TP;    -- �����ϱ���(1.����,2.����)
  T_EVENT_INFO.SELL_RT    := ;                         -- �ŵ���
  
  PKG_EIR_NESTED_NSC.PR_APPLY_ADD_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5)�ŷ����� ���(�������� ���)
  --   * T_EVENT_RESULT �����͸� ������ �������� ����
  --   * ���������� �ʿ��� ��ȸ �� ��� ���� ���� ����
  ----------------------------------------------------------------------------------------------------
  
  -- �ŵ� ��������
  I_BOND_TRADE.BOND_EIR        := T_EVENT_RESULT.EIR;                                        -- ��ȿ������
  I_BOND_TRADE.TOT_DCNT        := ISS.FN_CALC_DAYS();                                        -- ���ϼ�
  I_BOND_TRADE.SRV_DCNT        := ISS.FN_CALC_DAYS();                                        -- �����ϼ�
  I_BOND_TRADE.LPCNT           := ISS.FN_CALC_DAYS();                                        -- ����ϼ�
  I_BOND_TRADE.HOLD_DCNT       := ISS.FN_CALC_DAYS();                                        -- �����ϼ�
  I_BOND_TRADE.EXPR_DATE       := ;                                                          -- ��������
  
  I_BOND_TRADE.TOT_INT         := T_EVENT_RESULT.ACCRUED_INT;                                -- �����ڱݾ�
  I_BOND_TRADE.ACCRUED_INT     := T_EVENT_RESULT.ACCRUED_INT;                                -- �������
  I_BOND_TRADE.BTRM_UNPAID_INT := ;                                                          -- ����̼�����
  I_BOND_TRADE.TTRM_BOND_INT   := ;                                                          -- ���ä������
  
  I_BOND_TRADE.TRD_FACE_AMT    := I_BOND_TRADE.TRD_QTY * 1000;                               -- �Ÿž׸�(���� * 1000)
  I_BOND_TRADE.TRD_AMT         := TRUNC(I_BOND_TRADE.TRD_PRICE * I_BOND_TRADE.TRD_QTY / 10); -- �Ÿűݾ�(���� * �ܰ� / 10)
  I_BOND_TRADE.TRD_NET_AMT     := I_BOND_TRADE.TRD_AMT-I_BOND_TRADE.ACCRUED_INT;             -- �Ÿ�����ݾ�(�Ÿűݾ� - �������)
  I_BOND_TRADE.SANGGAK_AMT     := ;                                                          -- �󰢱ݾ�
  I_BOND_TRADE.BOOK_AMT        := I_BOND_TRADE.TRD_NET_AMT;                                  -- ��αݾ�
  I_BOND_TRADE.BOOK_PRC_AMT    := I_BOND_TRADE.TRD_NET_AMT;                                  -- ��ο���
  I_BOND_TRADE.TRD_PRFT        := ;                                                          -- �Ÿ�����
  I_BOND_TRADE.TRD_LOSS        := ;                                                          -- �Ÿż���
  I_BOND_TRADE.BTRM_EVAL_PRFT  := ;                                                          -- ����̽���������
  I_BOND_TRADE.BTRM_EVAL_LOSS  := ;                                                          -- ����̽����򰡼���
  I_BOND_TRADE.TXSTD_AMT       := ;                                                          -- ��ǥ�ݾ�
  I_BOND_TRADE.CORP_TAX        := ;                                                          -- ���޹��μ�
  I_BOND_TRADE.UNPAID_CORP_TAX := ;                                                          -- �����޹��μ�
  
  INSERT INTO BOND_TRADE VALUES I_BOND_TRADE;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 6)�ܰ� ������Ʈ
  ----------------------------------------------------------------------------------------------------
  UPDATE BOND_BALANCE 
     SET ROW = T_BOND_BALANCE
   WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- ��������(�ܰ� PK)
     AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- �ݵ��ڵ�(�ܰ� PK)
     AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- �����ڵ�(�ܰ� PK)
     AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- �ż�����(�ܰ� PK)
     AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- �ż��ܰ�(�ܰ� PK)
     AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ(�ܰ� PK)
  
  
  
  
  DBMS_OUTPUT.PUT_LINE('PR_SELL_BOND END');
  
END;