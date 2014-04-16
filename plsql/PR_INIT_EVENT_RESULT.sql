CREATE OR REPLACE PROCEDURE ISS.PR_INIT_EVENT_RESULT (
  I_EVENT_RESULT IN OUT EVENT_RESULT_EIR%ROWTYPE
) IS
BEGIN
  I_EVENT_RESULT.FUND_CODE      := ''; -- �ݵ��ڵ�
  I_EVENT_RESULT.BOND_CODE      := ''; -- �����ڵ�
  I_EVENT_RESULT.BUY_DATE       := ''; -- �ż�����
  I_EVENT_RESULT.BUY_PRICE      := 0;  -- �ż��ܰ�
  I_EVENT_RESULT.BALAN_SEQ      := 0;  -- �ܰ��Ϸù�ȣ
  I_EVENT_RESULT.EVENT_DATE     := ''; -- �̺�Ʈ�� (PK)
  I_EVENT_RESULT.EVENT_SEQ      := 0;  -- �̺�Ʈ SEQ (PK : ������ EVENT�Ͽ� 2���̻��� ������ EVENT �߻��ø� �����)
  I_EVENT_RESULT.EVENT_TYPE     := ''; -- Event ����(1.�ż�, 2.�ŵ�, 3.�ݸ�����, 4.�ջ�, 5.ȸ��)
  I_EVENT_RESULT.IR             := 0;  -- ǥ��������
  I_EVENT_RESULT.EIR            := 0;  -- ��ȿ������
  I_EVENT_RESULT.TOT_INT        := 0;  -- �����ڱݾ�
  I_EVENT_RESULT.ACCRUED_INT    := 0;  -- �������
  I_EVENT_RESULT.SANGGAK_AMT    := 0;  -- �󰢱ݾ�
  I_EVENT_RESULT.MI_SANGGAK_AMT := 0;  -- �̻󰢱ݾ�
  
END;