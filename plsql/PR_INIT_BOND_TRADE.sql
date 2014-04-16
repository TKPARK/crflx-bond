CREATE OR REPLACE PROCEDURE ISS.PR_INIT_BOND_TRADE (
  I_BOND_TRADE IN OUT BOND_TRADE%ROWTYPE
) IS
BEGIN
  I_BOND_TRADE.TRD_DATE            := ''; -- �ŷ�����
  I_BOND_TRADE.TRD_SEQ             := 0;  -- �ŷ��Ϸù�ȣ
  I_BOND_TRADE.FUND_CODE           := ''; -- �ݵ��ڵ�
  I_BOND_TRADE.BOND_CODE           := ''; -- �����ڵ�
  I_BOND_TRADE.BUY_DATE            := ''; -- �ż�����
  I_BOND_TRADE.BUY_PRICE           := 0;  -- �ż��ܰ�
  I_BOND_TRADE.BALAN_SEQ           := 0;  -- �ܰ��Ϸù�ȣ
  I_BOND_TRADE.TRD_TYPE_CD         := ''; -- �Ÿ������ڵ�(1.�μ�, 2.���ż�, 3.���ŵ�, 4.��ȯ)
  I_BOND_TRADE.GOODS_BUY_SELL_SECT := ''; -- ��ǰ�ż��ŵ�����(1.�ż�, 2.�ŵ�, 3.�ݸ�����, 4.�ջ�, 5.ȸ��)
  I_BOND_TRADE.STT_TERM_SECT       := ''; -- �����Ⱓ����(1.����, 2.����)
  I_BOND_TRADE.SETL_DATE           := ''; -- ��������
  I_BOND_TRADE.EXPR_DATE           := ''; -- ��������
  I_BOND_TRADE.EVENT_DATE          := ''; -- �̺�Ʈ�� (PK)
  I_BOND_TRADE.EVENT_SEQ           := 0;  -- �̺�Ʈ SEQ
  I_BOND_TRADE.TRD_PRICE           := 0;  -- �ŸŴܰ�
  I_BOND_TRADE.TRD_QTY             := 0;  -- �Ÿż���
  I_BOND_TRADE.TRD_FACE_AMT        := 0;  -- �Ÿž׸�
  I_BOND_TRADE.TRD_AMT             := 0;  -- �Ÿűݾ�
  I_BOND_TRADE.TRD_NET_AMT         := 0;  -- �Ÿ�����ݾ�
  I_BOND_TRADE.TOT_INT             := 0;  -- �����ڱݾ�
  I_BOND_TRADE.ACCRUED_INT         := 0;  -- �������
  I_BOND_TRADE.BTRM_UNPAID_INT     := 0;  -- ����̼�����
  I_BOND_TRADE.TTRM_BOND_INT       := 0;  -- ���ä������
  I_BOND_TRADE.TOT_DCNT            := 0;  -- ���ϼ�
  I_BOND_TRADE.SRV_DCNT            := 0;  -- �����ϼ�
  I_BOND_TRADE.LPCNT               := 0;  -- ����ϼ�
  I_BOND_TRADE.HOLD_DCNT           := 0;  -- �����ϼ�
  I_BOND_TRADE.BOND_EIR            := 0;  -- ��ȿ������
  I_BOND_TRADE.BOND_IR             := 0;  -- ǥ��������
  I_BOND_TRADE.DSCT_SANGGAK_AMT    := 0;  -- ���λ󰢱ݾ�
  I_BOND_TRADE.EX_CHA_SANGGAK_AMT  := 0;  -- �����󰢱ݾ�
  I_BOND_TRADE.MI_SANGGAK_AMT      := 0;  -- �̻󰢱ݾ�
  I_BOND_TRADE.BOOK_AMT            := 0;  -- ��αݾ�
  I_BOND_TRADE.BOOK_PRC_AMT        := 0;  -- ��ο���
  I_BOND_TRADE.TRD_PRFT            := 0;  -- �Ÿ�����
  I_BOND_TRADE.TRD_LOSS            := 0;  -- �Ÿżս�
  I_BOND_TRADE.BTRM_EVAL_PRFT      := 0;  -- ����������
  I_BOND_TRADE.BTRM_EVAL_LOSS      := 0;  -- �����򰡼ս�
  I_BOND_TRADE.TXSTD_AMT           := 0;  -- ��ǥ�ݾ�
  I_BOND_TRADE.CORP_TAX            := 0;  -- ���޹��μ�
  I_BOND_TRADE.UNPAID_CORP_TAX     := 0;  -- �����޹��μ�
  
END;