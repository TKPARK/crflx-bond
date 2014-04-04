CREATE OR REPLACE FUNCTION ISS.FN_INIT_EVENT_RESULT
  RETURN EVENT_RESULT_NESTED_S%ROWTYPE AS
  T_EVENT_RESULT EVENT_RESULT_NESTED_S%ROWTYPE;
BEGIN
  T_EVENT_RESULT.FUND_CODE      := ''; -- �ݵ��ڵ�
  T_EVENT_RESULT.BOND_CODE      := ''; -- �����ڵ�
  T_EVENT_RESULT.BUY_DATE       := ''; -- �ż�����
  T_EVENT_RESULT.BUY_PRICE      := 0;  -- �ż��ܰ�
  T_EVENT_RESULT.BALAN_SEQ      := 0;  -- �ܰ��Ϸù�ȣ
  T_EVENT_RESULT.EVENT_DATE     := ''; -- �̺�Ʈ�� (PK)
  T_EVENT_RESULT.EVENT_SEQ      := 0;  -- �̺�Ʈ SEQ (PK : ������ EVENT�Ͽ� 2���̻��� ������ EVENT �߻��ø� �����)
  T_EVENT_RESULT.EVENT_TYPE     := ''; -- Event ����(1.�ż�, 2.�ŵ�, 3.�ݸ�����, 4.�ջ�, 5.ȸ��)
  T_EVENT_RESULT.IR             := 0;  -- ǥ��������
  T_EVENT_RESULT.EIR            := 0;  -- ��ȿ������
  T_EVENT_RESULT.SELL_RT        := 0;  -- �ŵ���
  T_EVENT_RESULT.TOT_INT        := 0;  -- �����ڱݾ�
  T_EVENT_RESULT.ACCRUED_INT    := 0;  -- �������
  T_EVENT_RESULT.SANGGAK_AMT    := 0;  -- �󰢱ݾ�
  T_EVENT_RESULT.MI_SANGGAK_AMT := 0;  -- �̻󰢱ݾ�
  
  RETURN T_EVENT_RESULT;
END;