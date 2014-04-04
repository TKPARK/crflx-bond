CREATE OR REPLACE FUNCTION ISS.FN_INIT_BOND_TRADE
  RETURN BOND_TRADE%ROWTYPE AS
  T_BOND_TRADE BOND_TRADE%ROWTYPE;
BEGIN
  T_BOND_TRADE.TRD_DATE            := ''; -- �ŷ�����
  T_BOND_TRADE.TRD_SEQ             := 0;  -- �ŷ��Ϸù�ȣ
  T_BOND_TRADE.FUND_CODE           := ''; -- �ݵ��ڵ�
  T_BOND_TRADE.BOND_CODE           := ''; -- �����ڵ�
  T_BOND_TRADE.BUY_DATE            := ''; -- �ż�����
  T_BOND_TRADE.BUY_PRICE           := 0;  -- �ż��ܰ�
  T_BOND_TRADE.BALAN_SEQ           := 0;  -- �ܰ��Ϸù�ȣ
  T_BOND_TRADE.TRD_TYPE_CD         := ''; -- �Ÿ������ڵ�(1.�μ�, 2.���ż�, 3.���ŵ�, 4.��ȯ)
  T_BOND_TRADE.GOODS_BUY_SELL_SECT := ''; -- ��ǰ�ż��ŵ�����(1.�ż�, 2.�ŵ�, 3.�ݸ�����, 4.�ջ�, 5.ȸ��)
  T_BOND_TRADE.STT_TERM_SECT       := ''; -- �����Ⱓ����(1.����, 2.����)
  T_BOND_TRADE.SETL_DATE           := ''; -- ��������
  T_BOND_TRADE.EXPR_DATE           := ''; -- ��������
  T_BOND_TRADE.EVENT_DATE          := ''; -- �̺�Ʈ�� (PK)
  T_BOND_TRADE.EVENT_SEQ           := 0;  -- �̺�Ʈ SEQ
  T_BOND_TRADE.TRD_PRICE           := 0;  -- �ŸŴܰ�
  T_BOND_TRADE.TRD_QTY             := 0;  -- �Ÿż���
  T_BOND_TRADE.TRD_FACE_AMT        := 0;  -- �Ÿž׸�
  T_BOND_TRADE.TRD_AMT             := 0;  -- �Ÿűݾ�
  T_BOND_TRADE.TRD_NET_AMT         := 0;  -- �Ÿ�����ݾ�
  T_BOND_TRADE.TOT_INT             := 0;  -- �����ڱݾ�
  T_BOND_TRADE.ACCRUED_INT         := 0;  -- �������
  T_BOND_TRADE.BTRM_UNPAID_INT     := 0;  -- ����̼�����
  T_BOND_TRADE.TTRM_BOND_INT       := 0;  -- ���ä������
  T_BOND_TRADE.TOT_DCNT            := 0;  -- ���ϼ�
  T_BOND_TRADE.SRV_DCNT            := 0;  -- �����ϼ�
  T_BOND_TRADE.LPCNT               := 0;  -- ����ϼ�
  T_BOND_TRADE.HOLD_DCNT           := 0;  -- �����ϼ�
  T_BOND_TRADE.BOND_EIR            := 0;  -- ��ȿ������
  T_BOND_TRADE.BOND_IR             := 0;  -- ǥ��������
  T_BOND_TRADE.SANGGAK_AMT         := 0;  -- �󰢱ݾ�
  T_BOND_TRADE.MI_SANGGAK_AMT      := 0;  -- �̻󰢱ݾ�
  T_BOND_TRADE.BOOK_AMT            := 0;  -- ��αݾ�
  T_BOND_TRADE.BOOK_PRC_AMT        := 0;  -- ��ο���
  T_BOND_TRADE.TRD_PRFT            := 0;  -- �Ÿ�����
  T_BOND_TRADE.TRD_LOSS            := 0;  -- �Ÿżս�
  T_BOND_TRADE.BTRM_EVAL_PRFT      := 0;  -- ����������
  T_BOND_TRADE.BTRM_EVAL_LOSS      := 0;  -- �����򰡼ս�
  T_BOND_TRADE.TXSTD_AMT           := 0;  -- ��ǥ�ݾ�
  T_BOND_TRADE.CORP_TAX            := 0;  -- ���޹��μ�
  T_BOND_TRADE.UNPAID_CORP_TAX     := 0;  -- �����޹��μ�
  
  RETURN T_BOND_TRADE;
END;