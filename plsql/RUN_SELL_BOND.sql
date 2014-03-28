DECLARE
  T_EVENT_INFO PKG_EIR_TKP_S.EVENT_INFO_TYPE; -- EVENT INFO
  T_EIR_C PKG_EIR_TKP_S.EIR_CALC_INFO; -- EIR CALC INFO
BEGIN
  -- EVENT INFO
  T_EVENT_INFO.BOND_CODE := 'KR01TKPARK'; -- Bond Code(ä���ܰ��� PK)
  T_EVENT_INFO.BUY_DATE := '20121130'; -- Buy Date (ä���ܰ��� PK)
  T_EVENT_INFO.EVENT_DATE := '20121210'; -- �̺�Ʈ�� (PK)
  T_EVENT_INFO.EVENT_TYPE := '2'; -- Event ����(PK) : 1.�ż�, 2.�ŵ�, 3.�ݸ�����, 4.�ջ�, 5.ȸ��
  T_EVENT_INFO.SELL_RT := 0.2; -- �ŵ���
  
  -- EIR CALC INFO
  T_EIR_C.EVENT_DATE := T_EVENT_INFO.EVENT_DATE; -- EVENT �߻��� (������)
  T_EIR_C.BOND_TYPE := '3'; -- ä������(1.��ǥä, 2.����ä, 3.�ܸ�ä(�����Ͻ�), 4.����ä)
  T_EIR_C.ISSUE_DATE := '20121120'; -- ������
  T_EIR_C.EXPIRE_DATE := '20141120'; -- ������

  
  -- ä�� ���� �ŵ�
  PKG_EIR_TKP_S.PR_SELL_BOND(T_EVENT_INFO, T_EIR_C);
  
END;