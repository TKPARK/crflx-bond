DECLARE
  O_PRO_CN NUMBER := 0;
BEGIN
  -- �ջ�
  PR_ADD_DAMAGE_BOND('20121231'  -- �ջ�����
                   , 'KR_��ǥä' -- �ջ�����
                   , 10690       -- �ջ�ܰ�
                   , '3'         -- �ջ󱸺�(2.�߰��ջ�, 3. ȯ��)
                   , O_PRO_CN);
  
  DBMS_OUTPUT.PUT_LINE('O_PRO_CN=' || O_PRO_CN);
  
END;