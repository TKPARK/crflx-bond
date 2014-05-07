CREATE OR REPLACE PROCEDURE ISS.PR_INIT_BOND_DAMAGE (
  I_BOND_DAMAGE IN OUT BOND_DAMAGE%ROWTYPE
) IS
BEGIN
  I_BOND_DAMAGE.DAMAGE_DT           := ''; -- �ջ�����(PK)
  I_BOND_DAMAGE.DAMAGE_SEQ          := 0;  -- �ջ��Ϸù�ȣ(PK)
  I_BOND_DAMAGE.FUND_CODE           := ''; -- �ݵ��ڵ�
  I_BOND_DAMAGE.BOND_CODE           := ''; -- �����ڵ�
  I_BOND_DAMAGE.BUY_DATE            := ''; -- �ż�����
  I_BOND_DAMAGE.BUY_PRICE           := 0;  -- �ż��ܰ�
  I_BOND_DAMAGE.BALAN_SEQ           := 0;  -- �ܰ��Ϸù�ȣ
  I_BOND_DAMAGE.EVENT_DATE          := ''; -- �̺�Ʈ��
  I_BOND_DAMAGE.EVENT_SEQ           := 0;  -- �̺�Ʈ SEQ
  I_BOND_DAMAGE.CANCEL_YN           := ''; -- ��ҿ���(Y/N)
  I_BOND_DAMAGE.DAMAGE_TYPE         := ''; -- �ջ󱸺�(1.�ջ�, 2.�߰��ջ�, 3. ȯ��, 4.���)
  I_BOND_DAMAGE.DAMAGE_PRICE        := 0;  -- �ջ�ܰ�
  I_BOND_DAMAGE.DAMAGE_QTY          := 0;  -- �ջ����
  I_BOND_DAMAGE.DAMAGE_EVAL_AMT     := 0;  -- �ջ��򰡱ݾ�
  I_BOND_DAMAGE.CHBF_BOOK_AMT       := 0;  -- ������ ��αݾ�
  I_BOND_DAMAGE.CHBF_BOOK_PRC_AMT   := 0;  -- ������ ��ο���
  I_BOND_DAMAGE.CHAF_BOOK_AMT       := 0;  -- ������ ��αݾ�
  I_BOND_DAMAGE.CHAF_BOOK_PRC_AMT   := 0;  -- ������ ��ο���
  I_BOND_DAMAGE.ACCRUED_INT         := 0;  -- �������
  I_BOND_DAMAGE.BTRM_UNPAID_INT     := 0;  -- ����̼�����
  I_BOND_DAMAGE.TTRM_UNPAID_INT     := 0;  -- ���̼�����
  I_BOND_DAMAGE.DSCT_SANGGAK_AMT    := 0;  -- ���λ󰢱ݾ�
  I_BOND_DAMAGE.EX_CHA_SANGGAK_AMT  := 0;  -- �����󰢱ݾ�
  I_BOND_DAMAGE.CHBF_BTRM_EVAL_PRFT := 0;  -- ������ ����������
  I_BOND_DAMAGE.CHBF_BTRM_EVAL_LOSS := 0;  -- ������ �����򰡼ս�
  I_BOND_DAMAGE.REDUCTION_AM        := 0;  -- ���ױݾ�
  
END;