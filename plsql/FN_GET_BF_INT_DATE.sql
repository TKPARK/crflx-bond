CREATE OR REPLACE FUNCTION ISS.FN_GET_BF_INT_DATE (
  -- FROM ~ TO �ϼ����
    I_ISSUE_DATE CHAR   -- ������
  , I_BASE_DATE  CHAR   -- ������
  , I_INT_CYCLE  NUMBER -- �����ֱ�(��)
  ) RETURN CHAR AS
  T_INT_CNT     NUMBER; -- ���ڹ߻�Ƚ��
  T_BF_INT_DATE CHAR(8); -- ��������������
BEGIN
  T_INT_CNT := TRUNC(MONTHS_BETWEEN(I_BASE_DATE, I_ISSUE_DATE) / I_INT_CYCLE);
  T_BF_INT_DATE := TO_CHAR(ADD_MONTHS(I_ISSUE_DATE, T_INT_CNT*I_INT_CYCLE), 'YYYYMMDD');
  RETURN T_BF_INT_DATE;
END;