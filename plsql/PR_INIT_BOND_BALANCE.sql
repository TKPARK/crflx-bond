CREATE OR REPLACE PROCEDURE ISS.PR_INIT_BOND_BALANCE (
  I_BOND_BALANCE IN OUT BOND_BALANCE%ROWTYPE
) IS
BEGIN
  I_BOND_BALANCE.BIZ_DATE        := '';  -- ��������(PK)
  I_BOND_BALANCE.FUND_CODE       := '';  -- �ݵ��ڵ�(PK)
  I_BOND_BALANCE.BOND_CODE       := '';  -- �����ڵ�(PK)
  I_BOND_BALANCE.BUY_DATE        := '';  -- �ż�����(PK)
  I_BOND_BALANCE.BUY_PRICE       := 0;   -- �ż��ܰ�(PK)
  I_BOND_BALANCE.BALAN_SEQ       := 0;   -- �ܰ��Ϸù�ȣ(PK)
  I_BOND_BALANCE.BOND_IR         := 0;   -- IR      
  I_BOND_BALANCE.BOND_EIR        := 0;   -- EIR     
  I_BOND_BALANCE.TOT_QTY         := 0;   -- ���ܰ����
  I_BOND_BALANCE.TDY_AVAL_QTY    := 0;   -- ���ϰ������
  I_BOND_BALANCE.NDY_AVAL_QTY    := 0;   -- ���ϰ������
  I_BOND_BALANCE.BOOK_AMT        := 0;   -- ��αݾ�
  I_BOND_BALANCE.BOOK_PRC_AMT    := 0;   -- ��ο���
  I_BOND_BALANCE.ACCRUED_INT     := 0;   -- �������
  I_BOND_BALANCE.BTRM_UNPAID_INT := 0;   -- ����̼�����
  I_BOND_BALANCE.TTRM_BOND_INT   := 0;   -- ���ä������
  I_BOND_BALANCE.SANGGAK_AMT     := 0;   -- �󰢱ݾ�(������)
  I_BOND_BALANCE.MI_SANGGAK_AMT  := 0;   -- �̻󰢱ݾ�(�̻�����)
  I_BOND_BALANCE.TRD_PRFT        := 0;   -- �Ÿ�����
  I_BOND_BALANCE.TRD_LOSS        := 0;   -- �Ÿżս�
  I_BOND_BALANCE.BTRM_EVAL_PRFT  := 0;   -- ����������
  I_BOND_BALANCE.BTRM_EVAL_LOSS  := 0;   -- �����򰡼ս�
  I_BOND_BALANCE.EVAL_PRICE      := 0;   -- �򰡴ܰ�
  I_BOND_BALANCE.EVAL_AMT        := 0;   -- �򰡱ݾ�
  I_BOND_BALANCE.TOT_EVAL_PRFT   := 0;   -- ����������
  I_BOND_BALANCE.TOT_EVAL_LOSS   := 0;   -- �����򰡼ս�
  I_BOND_BALANCE.TTRM_EVAL_PRFT  := 0;   -- ���������
  I_BOND_BALANCE.TTRM_EVAL_LOSS  := 0;   -- ����򰡼ս�
  I_BOND_BALANCE.AQST_QTY        := 0;   -- �μ�����
  I_BOND_BALANCE.DRT_SELL_QTY    := 0;   -- ���ŵ�����
  I_BOND_BALANCE.DRT_BUY_QTY     := 0;   -- ���ż�����
  I_BOND_BALANCE.TXSTD_AMT       := 0;   -- ��ǥ�ݾ�
  I_BOND_BALANCE.CORP_TAX        := 0;   -- ���޹��μ�
  I_BOND_BALANCE.UNPAID_CORP_TAX := 0;   -- �����޹��μ�
  I_BOND_BALANCE.DAMAGE_YN       := 'N'; -- �ջ󿩺�(Y/N)
  I_BOND_BALANCE.DAMAGE_DT       := '';  -- �ջ�����
  I_BOND_BALANCE.REDUCTION_AM    := 0;   -- ���ױݾ�
  
END;