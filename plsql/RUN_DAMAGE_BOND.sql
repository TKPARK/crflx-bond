DECLARE
  T_BOND_DAMAGE   BOND_DAMAGE%ROWTYPE;       -- OUTPUT
BEGIN
  -- �ջ�
  PR_DAMAGE_BOND('20130520'  -- �ջ�����
               , 'KR_��ǥä' -- �ջ�����
               , 10650       -- �ջ�ܰ�
               , T_BOND_DAMAGE);
    
END;