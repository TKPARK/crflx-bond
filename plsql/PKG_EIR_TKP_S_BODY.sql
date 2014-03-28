CREATE OR REPLACE PACKAGE BODY ISS.PKG_EIR_TKP_S AS

  -- ������� ���
  FUNCTION FN_CALC_ACCRUED_INT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_ACCRUED_INT NUMBER; -- �������
  BEGIN
    IF I_EIR_C.BOND_TYPE = '1' THEN -- 1.��ǥä
      T_ACCRUED_INT := FN_GET_CPN_ACCRUED_INT(I_EIR_C);
    ELSIF I_EIR_C.BOND_TYPE = '2' THEN -- 2.����ä
      T_ACCRUED_INT := FN_GET_DISCNT_ACCRUED_INT(I_EIR_C);
    ELSIF I_EIR_C.BOND_TYPE = '3' THEN -- 3.�ܸ�ä(�����Ͻ�)
      T_ACCRUED_INT := FN_GET_SIMPLE_ACCRUED_INT(I_EIR_C);
    ELSIF I_EIR_C.BOND_TYPE = '4' THEN -- 4.����ä
      T_ACCRUED_INT := FN_GET_CPND_ACCRUED_INT(I_EIR_C);
    END IF;
    
    -- OUTPUT
    --DBMS_OUTPUT.PUT_LINE('ACCRUED_INT=' || FN_ROUND(T_ACCRUED_INT));
    
    RETURN FN_ROUND(T_ACCRUED_INT);
  END;


  -- ������� : ��ǥä(�ܸ�)(coupon bond)
  -- �׸�ݾ� * ������ * (����� - ��������������) / 365
  FUNCTION FN_GET_CPN_ACCRUED_INT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_ACCRUED_INT NUMBER; -- �������
    T_BF_INT_DATE CHAR(8); -- ��������������
    T_DAYS NUMBER; -- �ϼ�
  BEGIN
    -- 1.�������������� ���
    T_BF_INT_DATE := FN_GET_BF_INT_DATE(I_EIR_C);
    
    -- 2.(����� - ��������������) ���
    T_DAYS := FN_CALC_DAYS(T_BF_INT_DATE, I_EIR_C.EVENT_DATE);
    
    -- 3.������� ���
    T_ACCRUED_INT := I_EIR_C.FACE_AMT * I_EIR_C.IR * T_DAYS / 365;
    RETURN T_ACCRUED_INT;
  END;
  
  
  -- ������� : ����ä(discount debenture)
  FUNCTION FN_GET_DISCNT_ACCRUED_INT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_ACCRUED_INT NUMBER; -- �������
  BEGIN
    T_ACCRUED_INT := 0;
    RETURN T_ACCRUED_INT;
  END;


  -- ������� : �ܸ�ä(����)(simple interest bond)
  -- �׸�ݾ� * ������ * (����� - ������) / 365
  FUNCTION FN_GET_SIMPLE_ACCRUED_INT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_ACCRUED_INT NUMBER; -- �������
    T_DAYS NUMBER; -- �ϼ�
  BEGIN
    -- 1.(����� - ������) ���
    T_DAYS := FN_CALC_DAYS(I_EIR_C.ISSUE_DATE, I_EIR_C.EVENT_DATE);
    
    -- 2.������� ���
    T_ACCRUED_INT := I_EIR_C.FACE_AMT * I_EIR_C.IR * T_DAYS / 365;
    RETURN T_ACCRUED_INT;
  END;


  -- ������� : ����ä(compound bond)
  -- �׸�ݾ� * (1+IR/������Ƚ��)^����Ƚ��
  -- �غ���Ƚ�� = (������~�������ڱ����ϱ����� Ƚ��) + (�����-�������ڱ�����) / (�������ڱ�����-�������ڱ�����)
  FUNCTION FN_GET_CPND_ACCRUED_INT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_ACCRUED_INT NUMBER; -- �������
    T_CPND_BOND_CNT NUMBER; -- ����Ƚ��
    T_INT_CNT NUMBER; -- ���ڹ߻�Ƚ��
    T_BF_INT_DATE CHAR(8); -- ��������������
    T_AF_INT_DATE CHAR(8); -- ��������������
  BEGIN
    -- 1.����Ƚ�� ���
    T_INT_CNT := FN_GET_INT_CNT(I_EIR_C);
    T_BF_INT_DATE := FN_GET_BF_INT_DATE(I_EIR_C);
    T_AF_INT_DATE := FN_GET_AF_INT_DATE(I_EIR_C);
    T_CPND_BOND_CNT := T_INT_CNT + FN_CALC_DAYS(T_BF_INT_DATE, I_EIR_C.EVENT_DATE) / FN_CALC_DAYS(T_BF_INT_DATE, T_AF_INT_DATE);
    
    -- 2.������� ���
    T_ACCRUED_INT := I_EIR_C.FACE_AMT * POWER((1+I_EIR_C.IR/(12/I_EIR_C.INT_CYCLE)), T_CPND_BOND_CNT) - I_EIR_C.FACE_AMT;
        
    RETURN T_ACCRUED_INT;
  END;
  
  
  -- ���� ��� : (1.��ǥä, 2.����ä, 3.�ܸ�ä(�����Ͻ�))
  FUNCTION FN_GET_CAL_INT(BOND_TYPE CHAR, I_DAYS NUMBER, I_FACE_AMT NUMBER, I_IR NUMBER)
    RETURN NUMBER AS
    T_INT NUMBER; -- ����
  BEGIN
    IF BOND_TYPE = '1' OR BOND_TYPE = '3' THEN
      T_INT := I_FACE_AMT * I_IR * I_DAYS / 365;
    ELSIF BOND_TYPE = '2' THEN
      T_INT := 0;
    END IF;
    RETURN T_INT;
  END;
  
  
  -- ���� ��� : (4.����ä)
  FUNCTION FN_GET_CAL_CPND_INT(I_EIR_C EIR_CALC_INFO, I_BF_BASE_DATE CHAR, I_BASE_DATE CHAR)
    RETURN NUMBER AS
    T_BF_INT NUMBER; -- �� ����
    T_INT NUMBER; -- �� ����
    
    T_BF_EIR_C EIR_CALC_INFO := I_EIR_C; -- BEFORE
    T_EIR_C EIR_CALC_INFO := I_EIR_C; -- CURRENT
    
    T_CPND_BOND_CNT NUMBER; -- ����Ƚ��
    T_INT_CNT NUMBER; -- ���ڹ߻�Ƚ��
    T_BF_INT_DATE CHAR(8); -- ��������������
    T_AF_INT_DATE CHAR(8); -- ��������������
  BEGIN
    -- �� ���������� ���� ��� 1.����Ƚ�� ���
    T_BF_EIR_C.EVENT_DATE := I_BASE_DATE;
    T_INT_CNT := FN_GET_INT_CNT(T_BF_EIR_C);
    T_BF_INT_DATE := FN_GET_BF_INT_DATE(T_BF_EIR_C);
    T_AF_INT_DATE := FN_GET_AF_INT_DATE(T_BF_EIR_C);
    T_CPND_BOND_CNT := T_INT_CNT + FN_CALC_DAYS(T_BF_INT_DATE, T_BF_EIR_C.EVENT_DATE) / FN_CALC_DAYS(T_BF_INT_DATE, T_AF_INT_DATE);
    -- �� ���������� ���� ��� 2.���� ���
    T_INT := I_EIR_C.FACE_AMT * POWER((1+I_EIR_C.IR/(12/I_EIR_C.INT_CYCLE)), T_CPND_BOND_CNT) - I_EIR_C.FACE_AMT;

    -- �� ���������� ���� ��� 1.����Ƚ�� ���
    T_BF_EIR_C.EVENT_DATE := I_BF_BASE_DATE;
    T_INT_CNT := FN_GET_INT_CNT(I_EIR_C);
    T_BF_INT_DATE := FN_GET_BF_INT_DATE(I_EIR_C);
    T_AF_INT_DATE := FN_GET_AF_INT_DATE(I_EIR_C);
    T_CPND_BOND_CNT := T_INT_CNT + FN_CALC_DAYS(T_BF_INT_DATE, I_EIR_C.EVENT_DATE) / FN_CALC_DAYS(T_BF_INT_DATE, T_AF_INT_DATE);
    -- �� ���������� ���� ��� 2.���� ���
    T_BF_INT := I_EIR_C.FACE_AMT * POWER((1+I_EIR_C.IR/(12/I_EIR_C.INT_CYCLE)), T_CPND_BOND_CNT) - I_EIR_C.FACE_AMT;
    
    -- ����ä ���� = �� ���� - �� ����
    RETURN (T_INT-T_BF_INT);
  END;
  
  
  
  -- Cash Flow
  FUNCTION FN_CREATE_CASH_FLOWS (I_EIR_C EIR_CALC_INFO) 
    RETURN TABLE_CF_S AS
    T_INT_CYCLE NUMBER := I_EIR_C.INT_CYCLE; -- �����ֱ�(��)
    T_BF_BASE_DATE CHAR(8) := I_EIR_C.EVENT_DATE; -- ���� �����帧�߻���(����)
    T_AF_INT_DATE DATE; -- ��������������
    T_EXPIRE_DATE DATE := TO_DATE(I_EIR_C.EXPIRE_DATE, 'YYYYMMDD'); -- ������
    T_CF_LIST TABLE_CF_S := NEW TABLE_CF_S(); -- Cash Flow LIST
    T_CF_ITEM CF_TYPE_S; -- Cash Flow ITEM
  BEGIN
    -- �������
    T_CF_ITEM := FN_INIT_CF_TYPE_S(); -- INIT
    T_CF_ITEM.BASE_DATE := I_EIR_C.EVENT_DATE; -- �����帧�߻���
    T_CF_LIST.EXTEND;
    T_CF_LIST(T_CF_LIST.COUNT) := T_CF_ITEM;

    -- ����� ���� ���� ������ ���
    T_AF_INT_DATE := TO_DATE(FN_GET_AF_INT_DATE(I_EIR_C), 'YYYYMMDD');
    
    IF I_EIR_C.BOND_TYPE = '1' THEN -- [1.��ǥä]
      -- �������������� ~ �����ϱ��� CashFlow loop ����
      WHILE T_EXPIRE_DATE >= T_AF_INT_DATE LOOP
        T_CF_ITEM := FN_INIT_CF_TYPE_S(); -- INIT
        T_CF_ITEM.BASE_DATE := TO_CHAR(T_AF_INT_DATE, 'YYYYMMDD'); -- �����帧�߻���
        T_CF_ITEM.INT_DAYS := FN_CALC_DAYS(T_BF_BASE_DATE, TO_CHAR(T_AF_INT_DATE, 'YYYYMMDD')); -- �����ϼ�
        T_CF_ITEM.TOT_DAYS := FN_CALC_DAYS(I_EIR_C.EVENT_DATE, TO_CHAR(T_AF_INT_DATE, 'YYYYMMDD')); -- ���ϼ�(������-�����)
        T_CF_ITEM.INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, T_CF_ITEM.INT_DAYS, I_EIR_C.FACE_AMT, I_EIR_C.IR)); -- ���ڱݾ�
        
        -- �����Ͽ��� ���ݾ� �߻�
        IF T_CF_ITEM.BASE_DATE = I_EIR_C.EXPIRE_DATE THEN
          T_CF_ITEM.PRC_AMT := I_EIR_C.FACE_AMT; -- ���ݾ�
        END IF;
        
        T_CF_LIST.EXTEND;
        T_CF_LIST(T_CF_LIST.COUNT) := T_CF_ITEM;
        
        -- ���� �����帧�߻��Ϸ� �̵�
        T_BF_BASE_DATE := TO_CHAR(T_AF_INT_DATE, 'YYYYMMDD');
        T_AF_INT_DATE := ADD_MONTHS(T_AF_INT_DATE, T_INT_CYCLE);
      END LOOP;
    ELSE -- [2.����ä, 3.�ܸ�ä(�����Ͻ�), 4.����ä]
      T_CF_ITEM := FN_INIT_CF_TYPE_S(); -- INIT
      T_CF_ITEM.BASE_DATE := I_EIR_C.EXPIRE_DATE; -- �����帧�߻���
      T_CF_ITEM.INT_DAYS := FN_CALC_DAYS(I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE); -- �����ϼ�
      T_CF_ITEM.TOT_DAYS := FN_CALC_DAYS(I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE); -- ���ϼ�(������-�����)
      IF I_EIR_C.BOND_TYPE = '4' THEN -- [4.����ä]
        T_CF_ITEM.INT_AMT := FN_ROUND(FN_GET_CAL_CPND_INT(I_EIR_C, T_BF_BASE_DATE, I_EIR_C.EXPIRE_DATE)); -- ���ڱݾ�
      ELSE
        T_CF_ITEM.INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, T_CF_ITEM.INT_DAYS, I_EIR_C.FACE_AMT, I_EIR_C.IR)); -- ���ڱݾ�
      END IF;
      
      -- �����Ͽ��� ���ݾ� �߻�
      IF T_CF_ITEM.BASE_DATE = I_EIR_C.EXPIRE_DATE THEN
        T_CF_ITEM.PRC_AMT := I_EIR_C.FACE_AMT; -- ���ݾ�
      END IF;

      T_CF_LIST.EXTEND;
      T_CF_LIST(T_CF_LIST.COUNT) := T_CF_ITEM;
    END IF;
    
    -- OUTPUT
    /*FOR I IN 1..T_CF_LIST.COUNT LOOP
      T_CF_ITEM := T_CF_LIST(I);
      DBMS_OUTPUT.PUT_LINE(FN_GET_CASH_FLOW_STR(T_CF_ITEM));
    END LOOP;*/
    
    RETURN T_CF_LIST;
  END;
  
  
  -- EIR ã��
  -- 1.���� IR�� �׸��������� IR, ���������� ���� 1%(0.01)���� ����
  -- 2.�ٻ簪 EIR ã�� �Լ� ȣ��(Trial and error method)
  -- 3.���Ϲ��� �ٻ簪 EIR�� ������ �� ���� ����
  -- 4.(���簡ġ�� �� - ���ݾ�) == 0 �̸� loop�� �������´�
  --   0�� �ƴϸ� EIR�� IR�� �缳���ϰ�, ���������� �Ѵܰ� ������ ������ -> 2.�ٻ簪 EIR ã�� �Լ� ȣ��
  FUNCTION FN_GET_EIR(I_EIR_C EIR_CALC_INFO, I_CF_LIST IN OUT TABLE_CF_S)
    RETURN NUMBER AS
    T_EIR NUMBER(15,10) := I_EIR_C.IR; -- �׸������� ����
    T_UNIT NUMBER := 0.01; -- ���� 1%(0.01)
    T_SUM_CV NUMBER := 0; -- ���簡ġ�� ��
  BEGIN
    -- �Ҽ� 10�ڸ����� LOOP ����
    FOR I IN 1..10 LOOP
      -- CALL �ٻ� EIR ã��
      --DBMS_OUTPUT.PUT_LINE('---');
      --DBMS_OUTPUT.PUT_LINE('IN T_EIR='||T_EIR || ', T_UNIT='||T_UNIT);
      T_EIR := FN_GET_TRIAL_AND_ERROR(I_EIR_C, I_CF_LIST, T_EIR, T_UNIT);
      
      -- �� ����
      T_SUM_CV := 0;
      FOR I IN 1..I_CF_LIST.COUNT LOOP
        -- ���簡ġ(Current Value) = �����帧�հ� / POWER(1+EIR, ���ϼ�/365)
        I_CF_LIST(I).CUR_VALUE := FN_ROUND((I_CF_LIST(I).PRC_AMT+I_CF_LIST(I).INT_AMT) / POWER(1+T_EIR, I_CF_LIST(I).TOT_DAYS/365));
        T_SUM_CV := T_SUM_CV + I_CF_LIST(I).CUR_VALUE;
      END LOOP;
      --DBMS_OUTPUT.PUT_LINE('OUT T_EIR='||T_EIR || ', T_SUM_CV='||T_SUM_CV);
      
      -- ���簡ġ�� �հ� ���ݾ��� ���̱ݾ��� ����
      IF T_SUM_CV - I_EIR_C.BOOK_AMT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('FIND!!!');
        EXIT;
      END IF;
      
      T_UNIT := T_UNIT * 0.1;
    END LOOP;
    
    -- OUTPUT
    /*DBMS_OUTPUT.PUT_LINE('RETRUN T_EIR=' || FN_ROUND(T_EIR, 10));
    FOR I IN 1..I_CF_LIST.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(FN_GET_CASH_FLOW_STR(I_CF_LIST(I)));
    END LOOP;*/
    
    RETURN T_EIR;
  END;
  
  
  -- �ٻ� EIR ã��
  -- 1.�Ѱܹ��� IR(A)�� �������� ���簡ġ(CV)�� ���� ����
  -- 2.���̱ݾ� = ���簡ġ�� �� - ���ݾ�
  -- 3.���̱ݾ� 0 �̻��̸� increase
  --            0 �����̸� decrease
  -- 4.���̱ݾ��� ��ȣ�� �����Ǵ� ������ IR(B)�� ã�´�
  -- 5.IR(A), IR(B), ���̱ݾ�(A), ���̱ݾ�(B)�� ������ Trial and error Method �������� �ٻ簪 EIR�� ã�� ������
  FUNCTION FN_GET_TRIAL_AND_ERROR(I_EIR_C EIR_CALC_INFO, I_CF_LIST TABLE_CF_S, I_IR NUMBER, I_UNIT NUMBER)
    RETURN NUMBER AS
    T_EIR NUMBER := 0;
    A_IR NUMBER := I_IR;
    A_SUM_CV NUMBER := 0;
    A_DIFF_AMT NUMBER := 0;
    B_IR NUMBER := I_IR;
    B_SUM_CV NUMBER := 0;
    B_DIFF_AMT NUMBER := 0;
  BEGIN
    -- A.���簡ġ�� ��
    A_SUM_CV := 0;
    A_DIFF_AMT := 0;
    FOR I IN 1..I_CF_LIST.COUNT LOOP
      -- ���簡ġ(Current Value) = �����帧�հ� / POWER(1+EIR, ���ϼ�/365)
      A_SUM_CV := A_SUM_CV + FN_ROUND((I_CF_LIST(I).PRC_AMT+I_CF_LIST(I).INT_AMT) / POWER(1+A_IR, I_CF_LIST(I).TOT_DAYS/365));
    END LOOP;
    A_DIFF_AMT := A_SUM_CV - I_EIR_C.BOOK_AMT;
    --DBMS_OUTPUT.PUT_LINE('A_IR=' || A_IR || ', A_DIFF_AMT=' || A_DIFF_AMT);
    
    LOOP
      -- B.���簡ġ�� ��
      IF SIGN(A_DIFF_AMT) = 1 THEN
        B_IR := B_IR + I_UNIT;
      ELSE
        B_IR := B_IR - I_UNIT;
      END IF;
      --DBMS_OUTPUT.PUT_LINE('B_IR=' || B_IR);
      
      B_SUM_CV := 0;
      FOR J IN 1..I_CF_LIST.COUNT LOOP
        -- ���簡ġ(Current Value) = �����帧�հ� / POWER(1+EIR, ���ϼ�/365)
        B_SUM_CV := B_SUM_CV + FN_ROUND((I_CF_LIST(J).PRC_AMT+I_CF_LIST(J).INT_AMT) / POWER(1+B_IR, I_CF_LIST(J).TOT_DAYS/365));
      END LOOP;
      B_DIFF_AMT := B_SUM_CV - I_EIR_C.BOOK_AMT;
      --DBMS_OUTPUT.PUT_LINE('A_DIFF_AMT='||A_DIFF_AMT||', B_DIFF_AMT='||B_DIFF_AMT);
      
      EXIT WHEN SIGN(A_DIFF_AMT) <> SIGN(B_DIFF_AMT);
    END LOOP;
    
    -- IR(A), IR(B)�� ������ Trial and error Method �������� �ٻ簪 ���
    T_EIR := TRUNC(A_IR+(B_IR-A_IR)*(A_DIFF_AMT/(A_DIFF_AMT-B_DIFF_AMT)), 10);
    RETURN T_EIR;
  END;
  
  
  -- �� ���̺�
  -- 1.�󰢸���Ʈ�� ������ ���ڵ� ����(�� TYPE : 1.�ż�, 2.�ŵ�, 3.���ڼ���, 4.����, 5.�����, 6.����, 7.�ջ�, 8.ȸ��)
  -- 2.������ �󰢸���Ʈ ����
  -- 3.�󰢾׻�ǥ ó������(���ϼ� ���, �׸����� ���, ..)
  FUNCTION FN_GET_SANG_GAK(I_EIR_C EIR_CALC_INFO, I_CF_LIST TABLE_CF_S)
    RETURN TABLE_SGF_S AS
    T_SG_LIST TABLE_SGF_S := NEW TABLE_SGF_S();
    T_SG_ITEM SGF_TYPE_S; -- ����󰢽�����
    T_BF_SG_ITEM SGF_TYPE_S; -- ���󰢽�����
    T_LAST_MONTE_DATE DATE := TO_CHAR(LAST_DAY(I_EIR_C.EVENT_DATE), 'YYYYMMDD'); -- �����
    T_EXPIRE_DATE DATE := TO_DATE(I_EIR_C.EXPIRE_DATE, 'YYYYMMDD'); -- ������
    T_AF_INT_DATE DATE;
    T_REAL_INT_DATE CHAR(8);
  BEGIN
    -- 1-1.���ڵ� ����(�ż�)
    T_SG_ITEM := FN_INIT_SGF_TYPE_S(); -- INIT
    T_SG_ITEM.BASE_DATE := I_EIR_C.EVENT_DATE; -- EVENT �߻��� (������)
    T_SG_ITEM.SEQ := FN_GET_SGF_SEQ(T_SG_ITEM.BASE_DATE, T_SG_LIST);
    T_SG_ITEM.SANGGAK_TYPE := '1'; -- 1.�ż�
    T_SG_LIST.EXTEND;
    T_SG_LIST(T_SG_LIST.COUNT) := T_SG_ITEM;
    
    -- 1-2.���ڵ� ����(���ڼ���)
    IF I_EIR_C.BOND_TYPE = '1' THEN -- ��ǥä
      T_AF_INT_DATE := TO_DATE(FN_GET_AF_INT_DATE(I_EIR_C), 'YYYYMMDD'); -- ����� ���� ���� ������ ���
      WHILE T_EXPIRE_DATE > T_AF_INT_DATE LOOP -- �������������� ~ �����ϱ���
        T_SG_ITEM := FN_INIT_SGF_TYPE_S(); -- INIT
        T_SG_ITEM.BASE_DATE := TO_CHAR(T_AF_INT_DATE, 'YYYYMMDD');
        T_SG_ITEM.SEQ := FN_GET_SGF_SEQ(T_SG_ITEM.BASE_DATE, T_SG_LIST);
        T_SG_ITEM.SANGGAK_TYPE := '3'; -- 3.���ڼ���
        T_SG_LIST.EXTEND;
        T_SG_LIST(T_SG_LIST.COUNT) := T_SG_ITEM;
      
        T_AF_INT_DATE := ADD_MONTHS(T_AF_INT_DATE, I_EIR_C.INT_CYCLE);
      END LOOP;
  END IF;

    -- 1-3.���ڵ� ����(�����)
    WHILE T_EXPIRE_DATE > T_LAST_MONTE_DATE LOOP -- ����� ~ �����ϱ���
      T_SG_ITEM := FN_INIT_SGF_TYPE_S(); -- INIT
      T_SG_ITEM.BASE_DATE := TO_CHAR(T_LAST_MONTE_DATE, 'YYYYMMDD');
      T_SG_ITEM.SEQ := FN_GET_SGF_SEQ(T_SG_ITEM.BASE_DATE, T_SG_LIST);
      IF TO_CHAR(T_LAST_MONTE_DATE, 'MM') = '12' THEN
        T_SG_ITEM.SANGGAK_TYPE := '6'; -- 6.����
      ELSE
        T_SG_ITEM.SANGGAK_TYPE := '5'; -- 5.�����
      END IF;
      
      T_SG_LIST.EXTEND;
      T_SG_LIST(T_SG_LIST.COUNT) := T_SG_ITEM;
  
      T_LAST_MONTE_DATE := LAST_DAY(ADD_MONTHS(T_LAST_MONTE_DATE, 1));
    END LOOP;

    -- 1-4.���ڵ� ����(����)
    T_SG_ITEM := FN_INIT_SGF_TYPE_S(); -- INIT
    T_SG_ITEM.BASE_DATE := I_EIR_C.EXPIRE_DATE;
    T_SG_ITEM.SEQ := FN_GET_SGF_SEQ(T_SG_ITEM.BASE_DATE, T_SG_LIST);
    T_SG_ITEM.SANGGAK_TYPE := '4'; -- 4:����
    T_SG_LIST.EXTEND;
    T_SG_LIST(T_SG_LIST.COUNT) := T_SG_ITEM;
    

    -- 2.�󰢸���Ʈ ����
    --PR_QUICK_SORT(T_SG_LIST, 1, T_SG_LIST.COUNT);
    PR_SORT_SANGGAK_FLOWS(T_SG_LIST);

    
    -- 3.�󰢾׻�ǥ ó������
    T_BF_SG_ITEM := T_SG_LIST(1); -- ���󰢽�����
    T_BF_SG_ITEM.FACE_AMT := I_EIR_C.FACE_AMT; -- �׸�ݾ�
    T_BF_SG_ITEM.AF_BOOK_AMT := I_EIR_C.BOOK_AMT; -- ��αݾ�
    T_BF_SG_ITEM.AF_BOOK_AMT_EIR := I_EIR_C.BOOK_AMT; -- ��αݾ�
    T_REAL_INT_DATE := I_EIR_C.EVENT_DATE;
    FOR I IN 1..T_SG_LIST.COUNT LOOP
      ----------�󰢾� ��ǥ----------
      -- 1)�׸�ݾ�
      T_SG_LIST(I).FACE_AMT := FN_ROUND(T_BF_SG_ITEM.FACE_AMT);
      
      -- 2)���ϼ�(���󰢽������� �������� - ���󰢽������� ��������)
      T_SG_LIST(I).DAYS := FN_CALC_DAYS(T_BF_SG_ITEM.BASE_DATE, T_SG_LIST(I).BASE_DATE);
      
      ---------- ��ȿ���� ���� ----------
      -- ������αݾ�(���󰢽�����.�⸻��αݾ�)
      T_SG_LIST(I).BF_BOOK_AMT_EIR := T_BF_SG_ITEM.AF_BOOK_AMT_EIR;
      
      -- ��ȿ����(������αݾ�(EIR) * POWER(1 + EIR, ���ϼ�/365) -1))
      T_SG_LIST(I).EIR_INT_AMT := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT_EIR * (POWER(1+I_EIR_C.EIR, T_SG_LIST(I).DAYS/365) - 1));

      -- �����ڱݾ�(���������� OR �����Ͽ� ���� �߻��� �׸�����)
      IF I_EIR_C.BOND_TYPE = '1' THEN -- ��ǥä
        IF T_SG_LIST(I).SANGGAK_TYPE = '3' OR T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, FN_CALC_DAYS(T_REAL_INT_DATE, T_SG_LIST(I).BASE_DATE), T_SG_LIST(I).FACE_AMT, I_EIR_C.IR));
          T_REAL_INT_DATE := T_SG_LIST(I).BASE_DATE;
        END IF;
      ELSIF I_EIR_C.BOND_TYPE = '2' THEN -- ����ä
        T_SG_LIST(I).REAL_INT_AMT := 0;
      ELSIF I_EIR_C.BOND_TYPE = '3' THEN -- �ܸ�ä
        IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, FN_CALC_DAYS(T_REAL_INT_DATE, T_SG_LIST(I).BASE_DATE), T_SG_LIST(I).FACE_AMT, I_EIR_C.IR));
          T_REAL_INT_DATE := T_SG_LIST(I).BASE_DATE;
        END IF;
      ELSIF I_EIR_C.BOND_TYPE = '4' THEN -- ����ä
        IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_CPND_INT(I_EIR_C, T_BF_SG_ITEM.BASE_DATE, T_SG_LIST(I).BASE_DATE));
        END IF;
      END IF;
      
      -- �󰢱ݾ�(��ȿ���� - �����ڱݾ�)
      T_SG_LIST(I).SANGGAK_AMT_EIR := FN_ROUND(T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).REAL_INT_AMT);
      
      -- �⸻��αݾ�(������αݾ�(EIR) + �󰢾�(EIR))
      T_SG_LIST(I).AF_BOOK_AMT_EIR := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT_EIR + T_SG_LIST(I).SANGGAK_AMT_EIR);
      
      ----------�󰢾� ��ǥ----------
      -- 3)������αݾ�(���󰢽�����.�⸻��αݾ�)
      T_SG_LIST(I).BF_BOOK_AMT := T_BF_SG_ITEM.AF_BOOK_AMT;
      
      -- 4)�׸�����(�ǹ߻����� ������ �ƴ� �������)
      IF I_EIR_C.BOND_TYPE <> '4' THEN
        T_SG_LIST(I).FACE_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, T_SG_LIST(I).DAYS, T_SG_LIST(I).FACE_AMT, I_EIR_C.IR));
      ELSE
        -- �׸����� * ���ϼ� / ���ϼ�
        T_SG_LIST(I).FACE_INT_AMT := FN_ROUND(FN_GET_CAL_CPND_INT(I_EIR_C, I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE) * T_SG_LIST(I).DAYS / FN_CALC_DAYS(I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE));
      END IF;
      
      -- 5)�󰢾�(��ȿ���� - �׸�����)
      T_SG_LIST(I).SANGGAK_AMT := FN_ROUND(T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).FACE_INT_AMT);
      
      -- 6)�⸻��αݾ�(������αݾ� + �󰢾�)
      T_SG_LIST(I).AF_BOOK_AMT := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT + T_SG_LIST(I).SANGGAK_AMT);
      
      -- 7)�̻��ܾ�(�׸�ݾ� - �⸻��αݾ�)
      T_SG_LIST(I).MI_SANGGAK_AMT := FN_ROUND(T_SG_LIST(I).FACE_AMT - T_SG_LIST(I).AF_BOOK_AMT);
      
      
      -- �����Ͽ� �̻��ܾ��� 1�̻��̸� �ܼ����� ���� ���� �ƴ϶�, EIR�� ������ �ִ� ���̹Ƿ� ����ó��
--      IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
--        IF T_SG_LIST(I).MI_SANGGAK_AMT > 1 THEN
--          PCZ_RAISE(-20999, '�̻��ܾ��� 1�̻� ����(�̻��ܾ�:'||T_SG_LIST(I).MI_SANGGAK_AMT||')');
--        END IF;
--        
--        -- �������� ��ȿ���ڿ� ���� �̻��ܾ� ����ó��
--        IF T_SG_LIST(I).MI_SANGGAK_AMT <> 0 THEN
--          T_SG_LIST(I).EIR_INT_AMT := T_SG_LIST(I).EIR_INT_AMT + T_SG_LIST(I).MI_SANGGAK_AMT;
--          
--          T_SG_LIST(I).SANGGAK_AMT := T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).FACE_INT_AMT;
--          T_SG_LIST(I).AF_BOOK_AMT := T_SG_LIST(I).BF_BOOK_AMT + T_SG_LIST(I).SANGGAK_AMT;
--          T_SG_LIST(I).MI_SANGGAK_AMT := T_SG_LIST(I).FACE_AMT - T_SG_LIST(I).AF_BOOK_AMT;
--        END IF;
--      END IF;
      
      
      -- ����� ���� ���󰢽����� ����
      T_BF_SG_ITEM := T_SG_LIST(I);
    END LOOP;
    
    -- OUTPUT
    /*FOR I IN 1..T_SG_LIST.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(FN_GET_SANGGAK_FLOW_STR(T_SG_LIST(I)));
    END LOOP;*/
    
    RETURN T_SG_LIST;
  END;
  
  
  -- QUICK SORT
  PROCEDURE PR_QUICK_SORT(I_SG_LIST IN OUT TABLE_SGF_S, I_LOW IN NUMBER, I_HIGH IN NUMBER) IS
    T_I NUMBER := I_LOW;
    T_J NUMBER := I_HIGH;
    T_PIVOT SGF_TYPE_S := I_SG_LIST((I_LOW+I_HIGH)/2);
    T_TEMP SGF_TYPE_S;
  BEGIN
    LOOP
      WHILE (I_SG_LIST(T_I).BASE_DATE < T_PIVOT.BASE_DATE) LOOP
        T_I := T_I + 1;
      END LOOP;
      
      WHILE (I_SG_LIST(T_J).BASE_DATE > T_PIVOT.BASE_DATE) LOOP
        T_J := T_J - 1;
      END LOOP;
      
      IF T_I <= T_J THEN
        T_TEMP := I_SG_LIST(T_I);
        I_SG_LIST(T_I) := I_SG_LIST(T_J);
        I_SG_LIST(T_J) := T_TEMP;
        T_I := T_I + 1;
        T_J := T_J - 1;
      END IF;
    EXIT WHEN T_I > T_J;
    END LOOP;
    
    IF I_LOW < T_J THEN
      PR_QUICK_SORT(I_SG_LIST, I_LOW, T_J);
    END IF;
    
    IF T_I < I_HIGH THEN
      PR_QUICK_SORT(I_SG_LIST, T_I, I_HIGH);
    END IF;    
  END;
  
  
  -- Sort SangGak Flow List (�����ϱ��� ASC) Bubble Sort ����
  PROCEDURE PR_SORT_SANGGAK_FLOWS(O_SGF_LIST IN OUT TABLE_SGF_S) IS
    V_SWAPPED BOOLEAN := FALSE;
    V_SG_TEMP SGF_TYPE_S;
    V_SGF_1   SGF_TYPE_S;
    V_SGF_2   SGF_TYPE_S;
  BEGIN
    IF O_SGF_LIST.COUNT < 1 THEN RETURN; END IF;
    
    LOOP
      V_SWAPPED := FALSE;
      FOR I_IDX IN 2..O_SGF_LIST.COUNT LOOP
        V_SGF_1 := O_SGF_LIST(I_IDX -1);
        V_SGF_2 := O_SGF_LIST(I_IDX);
        -- �����Ϻ� Swap 
        IF V_SGF_1.BASE_DATE > V_SGF_2.BASE_DATE THEN
          V_SG_TEMP           := O_SGF_LIST(I_IDX);
          O_SGF_LIST(I_IDX)   := O_SGF_LIST(I_IDX-1);
          O_SGF_LIST(I_IDX-1) := V_SG_TEMP;
          V_SWAPPED := TRUE;    
        ELSIF V_SGF_1.BASE_DATE = V_SGF_2.BASE_DATE AND V_SGF_1.SEQ > V_SGF_2.SEQ THEN -- <EVENT_SEQ> ���� �������̸� SEQ ���� Swap
          V_SG_TEMP           := O_SGF_LIST(I_IDX);
          O_SGF_LIST(I_IDX)   := O_SGF_LIST(I_IDX-1);
          O_SGF_LIST(I_IDX-1) := V_SG_TEMP;
          V_SWAPPED := TRUE;
        END IF;
      END LOOP; -- END FOR I_IDX
      
      -- If we passed through table without swapping we are done, so exit
      EXIT WHEN NOT V_SWAPPED;
    END LOOP;
  END PR_SORT_SANGGAK_FLOWS;
  
  
  -- ä��(Event ������� EVENT_SEQ)
  FUNCTION FN_GET_EVENT_SEQ(I_EVENT_INFO EVENT_INFO_TYPE) RETURN NUMBER IS
    T_EVENT_SEQ NUMBER := 0;
  BEGIN
  
    SELECT NVL(MAX(EVENT_SEQ), 0) + 1 AS SEQ
      INTO T_EVENT_SEQ
      FROM EVENT_RESULT_N_S_TKP
     WHERE BOND_CODE = I_EVENT_INFO.BOND_CODE
       AND BUY_DATE = I_EVENT_INFO.BUY_DATE
       AND EVENT_DATE = I_EVENT_INFO.EVENT_DATE;
       
    RETURN T_EVENT_SEQ;
  END;
  
 
  -- ä��(�ܰ� BALAN_SEQ)
  FUNCTION FN_GET_BALAN_SEQ(I_BOND_BALANCE BOND_BALANCE%ROWTYPE) RETURN NUMBER IS
    T_BALAN_SEQ NUMBER := 0;
  BEGIN
  
    SELECT NVL(MAX(BALAN_SEQ), 0) + 1 AS SEQ
      INTO T_BALAN_SEQ
      FROM BOND_BALANCE
     WHERE BIZ_DATE = I_BOND_BALANCE.BIZ_DATE
       AND FUND_CODE = I_BOND_BALANCE.FUND_CODE
       AND BOND_CODE = I_BOND_BALANCE.BOND_CODE
       AND BUY_DATE = I_BOND_BALANCE.BUY_DATE
       AND BUY_PRICE = I_BOND_BALANCE.BUY_PRICE;
       
    RETURN T_BALAN_SEQ;
  END;
  
  
  -- ä��(�ŷ����� TRD_SEQ)
  FUNCTION FN_GET_TRD_SEQ(I_EVENT_INFO EVENT_INFO_TYPE) RETURN NUMBER IS
    T_TRD_SEQ NUMBER := 0;
  BEGIN
  
    SELECT NVL(MAX(TRD_SEQ), 0) + 1 AS SEQ
      INTO T_TRD_SEQ
      FROM BOND_TRADE
     WHERE TRD_DATE = I_EVENT_INFO.EVENT_DATE;
       
    RETURN T_TRD_SEQ;
  END;

  
  -- INSERT(Event �������)
  PROCEDURE PR_INSERT_EVENT_RESULT_INFO(I_EVENT_INFO EVENT_INFO_TYPE, I_CF_LIST TABLE_CF_S, I_SG_LIST TABLE_SGF_S) IS
    T_EVENT_SEQ NUMBER := 0; -- �̺�Ʈ SEQ
  BEGIN
    -- �̺�Ʈ SEQ ä��
    T_EVENT_SEQ := PKG_EIR_TKP_S.FN_GET_EVENT_SEQ(I_EVENT_INFO);
    
    INSERT INTO ISS.EVENT_RESULT_N_S_TKP VALUES (
      I_EVENT_INFO.BOND_CODE -- Bond Code(ä���ܰ��� PK)                                                 
    , I_EVENT_INFO.BUY_DATE -- Buy Date (ä���ܰ��� PK)                                                 
    , I_EVENT_INFO.EVENT_DATE -- �̺�Ʈ�� (PK)                                                            
    , T_EVENT_SEQ -- �̺�Ʈ SEQ (PK : ������ EVENT�Ͽ� 2���̻��� ������ EVENT �߻��ø� �����)
    , I_EVENT_INFO.EVENT_TYPE -- Event ���� : 1.�ż�, 2.�ŵ�, 3.�ݸ�����, 4.�ջ�, 5.ȸ��                  
    , I_EVENT_INFO.IR -- ǥ��������                                                               
    , I_EVENT_INFO.EIR -- ��ȿ������                                                               
    , I_EVENT_INFO.SELL_RT -- �ŵ���                                                                   
    , I_EVENT_INFO.FACE_AMT -- �׸�ݾ�                                                                 
    , I_EVENT_INFO.BOOK_AMT -- ��αݾ�                                                                 
    , I_CF_LIST -- Cash Flow List                                                           
    , I_SG_LIST -- SangGakFlow List                                                         
    );
    
    --COMMIT
    DBMS_OUTPUT.PUT_LINE('SUCCESS(EVENT_RESULT_N_S_TKP)');
    
  END PR_INSERT_EVENT_RESULT_INFO;
  
  
  -- INSERT(�ܰ�)
  PROCEDURE PR_INSERT_BOND_BALANCE(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO, I_ACCRUED_INT NUMBER) IS
    T_BOND_BALANCE BOND_BALANCE%ROWTYPE; -- �ܰ� ROWTYPE
    T_BOND_TRADE BOND_TRADE%ROWTYPE;     -- �ŷ����� ROWTYPE
    T_TRD_PRICE      NUMBER := (I_EVENT_INFO.BOOK_AMT + I_ACCRUED_INT) / 10000; -- �ŷ��ܰ�
    T_TRD_QTY        NUMBER := I_EVENT_INFO.FACE_AMT / 1000;                    -- �ŷ�����
    T_TRD_FACE_AMT   NUMBER := T_TRD_QTY * 1000;                                -- �ŷ��׸�(�ŷ����� * 1000)
    T_TRD_AMT        NUMBER := T_TRD_PRICE * T_TRD_QTY / 10;                    -- �ŷ��ݾ�(�ŷ��ܰ� * �ŷ����� / 10)
    T_BOOK_AMT       NUMBER := T_TRD_AMT - I_ACCRUED_INT;                       -- ��αݾ�(= �ŷ��ݾ� - �������)
    T_BOOK_PRC_AMT   NUMBER := T_TRD_AMT - I_ACCRUED_INT;                       -- ��ο���(= �ŷ��ݾ� - �������)
    T_MI_SANGGAK_AMT NUMBER := T_TRD_FACE_AMT - T_BOOK_AMT;                     -- �̻󰢱ݾ�(= �ŷ��׸� - ��αݾ�)
  BEGIN
    /* �ܰ� TABLE */
    -- PK
    T_BOND_BALANCE.BIZ_DATE := I_EVENT_INFO.EVENT_DATE; -- ��������
    T_BOND_BALANCE.FUND_CODE := I_EVENT_INFO.BOND_CODE; -- �ݵ��ڵ�
    T_BOND_BALANCE.BOND_CODE := I_EVENT_INFO.BOND_CODE; -- �����ڵ�
    T_BOND_BALANCE.BUY_DATE := I_EVENT_INFO.BUY_DATE; -- �ż�����
    T_BOND_BALANCE.BUY_PRICE := T_TRD_PRICE; -- �ż��ܰ�
    T_BOND_BALANCE.BALAN_SEQ := PKG_EIR_TKP_S.FN_GET_BALAN_SEQ(T_BOND_BALANCE); -- �ܰ��Ϸù�ȣ
    
    -- VALUE
    T_BOND_BALANCE.BOND_IR := I_EVENT_INFO.IR; -- IR
    T_BOND_BALANCE.BOND_EIR := I_EVENT_INFO.EIR; -- EIR
    T_BOND_BALANCE.TOT_QTY := T_TRD_QTY; -- ���ܰ����            
    T_BOND_BALANCE.TDY_AVAL_QTY := T_TRD_QTY; -- ���ϰ������          
    T_BOND_BALANCE.NDY_AVAL_QTY := T_TRD_QTY; -- ���ϰ������          
    T_BOND_BALANCE.BOOK_AMT := T_BOOK_AMT; -- ��αݾ�              
    T_BOND_BALANCE.BOOK_PRC_AMT := T_BOOK_PRC_AMT; -- ��ο���              
    T_BOND_BALANCE.ACCRUED_INT := I_ACCRUED_INT; -- �������              
    T_BOND_BALANCE.BTRM_UNPAID_INT := 0; -- ����̼�����          
    T_BOND_BALANCE.TTRM_BOND_INT := 0; -- ���ä������          
    T_BOND_BALANCE.SANGGAK_AMT := 0; -- �󰢱ݾ�(������)    
    T_BOND_BALANCE.MI_SANGGAK_AMT := T_MI_SANGGAK_AMT; -- �̻󰢱ݾ�(�̻�����)
    T_BOND_BALANCE.TRD_PRFT := 0; -- �Ÿ�����              
    T_BOND_BALANCE.TRD_LOSS := 0; -- �Ÿżս�              
    T_BOND_BALANCE.BTRM_EVAL_PRFT := 0; -- ����������          
    T_BOND_BALANCE.BTRM_EVAL_LOSS := 0; -- �����򰡼ս�          
    T_BOND_BALANCE.EVAL_PRICE := 0; -- �򰡴ܰ�              
    T_BOND_BALANCE.EVAL_AMT := 0; -- �򰡱ݾ�              
    T_BOND_BALANCE.TOT_EVAL_PRFT := 0; -- ����������          
    T_BOND_BALANCE.TOT_EVAL_LOSS := 0; -- �����򰡼ս�          
    T_BOND_BALANCE.TTRM_EVAL_PRFT := 0; -- ���������          
    T_BOND_BALANCE.TTRM_EVAL_LOSS := 0; -- ����򰡼ս�          
    T_BOND_BALANCE.AQST_QTY := 0; -- �μ�����              
    T_BOND_BALANCE.DRT_SELL_QTY := 0; -- ���ŵ�����            
    T_BOND_BALANCE.DRT_BUY_QTY := T_TRD_QTY; -- ���ż�����            
    T_BOND_BALANCE.TXSTD_AMT := 0; -- ��ǥ�ݾ�              
    T_BOND_BALANCE.CORP_TAX := 0; -- ���޹��μ�            
    T_BOND_BALANCE.UNPAID_CORP_TAX := 0; -- �����޹��μ�          
    
    -- COMMIT
    INSERT INTO ISS.BOND_BALANCE VALUES T_BOND_BALANCE;
    DBMS_OUTPUT.PUT_LINE('SUCCESS(BOND_BALANCE)');
    
    /* �ŷ����� TABLE */
     -- PK
    T_BOND_TRADE.TRD_DATE := I_EVENT_INFO.EVENT_DATE; -- �ŷ�����
    T_BOND_TRADE.TRD_SEQ := PKG_EIR_TKP_S.FN_GET_TRD_SEQ(I_EVENT_INFO); -- �ŷ��Ϸù�ȣ
    
    -- VALUE
    T_BOND_TRADE.FUND_CODE := T_BOND_BALANCE.FUND_CODE; -- �ݵ��ڵ�        
    T_BOND_TRADE.BOND_CODE := T_BOND_BALANCE.BOND_CODE; -- �����ڵ�        
    T_BOND_TRADE.BUY_DATE := T_BOND_BALANCE.BUY_DATE; -- �ż�����        
    T_BOND_TRADE.BUY_PRICE := T_BOND_BALANCE.BUY_PRICE; -- �ż��ܰ�        
    T_BOND_TRADE.BALAN_SEQ := T_BOND_BALANCE.BALAN_SEQ; -- �ܰ��Ϸù�ȣ    
    T_BOND_TRADE.TRD_TYPE_CD := '2'; -- �Ÿ������ڵ�(1.�μ�, 2.���ż�, 3.���ŵ�, 4.��ȯ)
    T_BOND_TRADE.GOODS_BUY_SELL_SECT := '1'; -- ��ǰ�ż��ŵ�����(1.��ǰ�ż�, 2.��ǰ�ŵ�)
    T_BOND_TRADE.STT_TERM_SECT := '0'; -- �����Ⱓ����(0.����, 1.����, 2.����(������))
    T_BOND_TRADE.SETL_DATE := I_EIR_C.EVENT_DATE; -- ��������        
    T_BOND_TRADE.EXPR_DATE := I_EIR_C.EXPIRE_DATE; -- ��������        
    T_BOND_TRADE.TRD_PRICE := T_TRD_PRICE; -- �ŸŴܰ�        
    T_BOND_TRADE.TRD_QTY := T_TRD_QTY; -- �Ÿż���        
    T_BOND_TRADE.TRD_FACE_AMT := T_TRD_FACE_AMT; -- �Ÿž׸�        
    T_BOND_TRADE.TRD_AMT := T_TRD_AMT; -- �Ÿűݾ�        
    T_BOND_TRADE.TRD_NET_AMT := T_BOOK_AMT; -- �Ÿ�����ݾ�    
    T_BOND_TRADE.TOT_INT := I_ACCRUED_INT; -- �����ڱݾ�      
    T_BOND_TRADE.ACCRUED_INT := I_ACCRUED_INT; -- �������        
    T_BOND_TRADE.BTRM_UNPAID_INT := 0; -- ����̼�����    
    T_BOND_TRADE.TTRM_BOND_INT := 0; -- ���ä������    
    T_BOND_TRADE.TOT_DCNT := 0; -- ���ϼ�          
    T_BOND_TRADE.SRV_DCNT := 0; -- �����ϼ�        
    T_BOND_TRADE.LPCNT := 0; -- ����ϼ�        
    T_BOND_TRADE.HOLD_DCNT := 0; -- �����ϼ�        
    T_BOND_TRADE.BOND_EIR := I_EVENT_INFO.EIR; -- ��ȿ������      
    T_BOND_TRADE.BOND_IR := I_EVENT_INFO.IR; -- ǥ��������      
    T_BOND_TRADE.SANGGAK_AMT := 0; -- �󰢱ݾ�        
    T_BOND_TRADE.MI_SANGGAK_AMT := 0; -- �̻󰢱ݾ�      
    T_BOND_TRADE.BOOK_AMT := T_BOOK_AMT; -- ��αݾ�        
    T_BOND_TRADE.BOOK_PRC_AMT := T_BOOK_PRC_AMT; -- ��ο���        
    T_BOND_TRADE.TRD_PRFT := 0; -- �Ÿ�����        
    T_BOND_TRADE.TRD_LOSS := 0; -- �Ÿżս�        
    T_BOND_TRADE.BTRM_EVAL_PRFT := 0; -- ����������    
    T_BOND_TRADE.BTRM_EVAL_LOSS := 0; -- �����򰡼ս�    
    T_BOND_TRADE.TXSTD_AMT := 0; -- ��ǥ�ݾ�        
    T_BOND_TRADE.CORP_TAX := 0; -- ���޹��μ�      
    T_BOND_TRADE.UNPAID_CORP_TAX := 0; -- �����޹��μ�    
    
    --COMMIT
    INSERT INTO ISS.BOND_TRADE VALUES T_BOND_TRADE;
    DBMS_OUTPUT.PUT_LINE('SUCCESS(BOND_TRADE)');

    
  END PR_INSERT_BOND_BALANCE;
  
  
  -- INSERT(�ŷ�����)
  PROCEDURE PR_INSERT_BOND_TRADE(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO, I_ACCRUED_INT NUMBER) IS
    T_BOND_TRADE BOND_TRADE%ROWTYPE; -- �ŷ����� ROWTYPE
  BEGIN
    -- PK
    T_BOND_TRADE.TRD_DATE := I_EVENT_INFO.EVENT_DATE; -- �ŷ�����
    T_BOND_TRADE.TRD_SEQ := PKG_EIR_TKP_S.FN_GET_TRD_SEQ(I_EVENT_INFO); -- �ŷ��Ϸù�ȣ
    
    --COMMIT
    INSERT INTO ISS.BOND_TRADE VALUES T_BOND_TRADE;
    DBMS_OUTPUT.PUT_LINE('SUCCESS');
  END PR_INSERT_BOND_TRADE;
 
  
  -- ä�� �ű� �ż�
  PROCEDURE PR_NEW_BUY_BOND(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO) IS
    T_EVENT_INFO EVENT_INFO_TYPE := I_EVENT_INFO; -- EVENT INFO
    T_EIR_C EIR_CALC_INFO := I_EIR_C; -- EIR CALC INFO
    T_ACCRUED_INT NUMBER := 0; -- �������
    T_CF_LIST TABLE_CF_S := NEW TABLE_CF_S(); -- Cash Flow LIST
    T_SG_LIST TABLE_SGF_S := NEW TABLE_SGF_S(); -- �� LIST
  BEGIN
    DBMS_OUTPUT.PUT_LINE('--- ������� ---');
    T_ACCRUED_INT := PKG_EIR_TKP_S.FN_CALC_ACCRUED_INT(T_EIR_C);
    DBMS_OUTPUT.PUT_LINE('T_ACCRUED_INT=' || T_ACCRUED_INT);
    
    DBMS_OUTPUT.PUT_LINE('--- Cash Flow ---');
    T_CF_LIST := PKG_EIR_TKP_S.FN_CREATE_CASH_FLOWS(T_EIR_C);
    FOR I IN 1..T_CF_LIST.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(PKG_EIR_TKP_S.FN_GET_CASH_FLOW_STR(T_CF_LIST(I)));
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('--- EIR ---');
    T_EIR_C.EIR := PKG_EIR_TKP_S.FN_GET_EIR(T_EIR_C, T_CF_LIST);
    T_EVENT_INFO.EIR := T_EIR_C.EIR;
    DBMS_OUTPUT.PUT_LINE('T_EIR_C.EIR=' || T_EIR_C.EIR);
    FOR I IN 1..T_CF_LIST.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(PKG_EIR_TKP_S.FN_GET_CASH_FLOW_STR(T_CF_LIST(I)));
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('--- �����̺� ---');
    T_SG_LIST := PKG_EIR_TKP_S.FN_GET_SANG_GAK(T_EIR_C, T_CF_LIST);
    FOR I IN 1..T_SG_LIST.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(PKG_EIR_TKP_S.FN_GET_SANGGAK_FLOW_STR(T_SG_LIST(I)));
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('--- INSERT(Event �������) ---');
    PKG_EIR_TKP_S.PR_INSERT_EVENT_RESULT_INFO(T_EVENT_INFO, T_CF_LIST, T_SG_LIST);
    
    DBMS_OUTPUT.PUT_LINE('--- INSERT(�ܰ�) ---');
    PKG_EIR_TKP_S.PR_INSERT_BOND_BALANCE(T_EVENT_INFO, T_EIR_C, T_ACCRUED_INT);
    
    --DBMS_OUTPUT.PUT_LINE('--- INSERT(�ŷ�����) ---');
    --PKG_EIR_TKP_S.PR_INSERT_BOND_TRADE(T_EVENT_INFO, T_EIR_C, T_ACCRUED_INT);

    
  END PR_NEW_BUY_BOND;
  
  
  -- ä�� ���� �ŵ�
  PROCEDURE PR_SELL_BOND(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO) IS
    T_EVENT_RESULT EVENT_RESULT_NESTED_S%ROWTYPE;
    T_EVENT_INFO EVENT_INFO_TYPE := I_EVENT_INFO; -- EVENT INFO
    T_SG_LIST TABLE_SGF_S := NEW TABLE_SGF_S(); -- �� LIST
    T_SG_ITEM SGF_TYPE_S; -- ����󰢽�����
    T_BF_SG_ITEM SGF_TYPE_S; -- ���󰢽�����
    T_BF_IDX NUMBER;
    T_REAL_INT_DATE CHAR(8);
    T_AF_FACE_AMT NUMBER; -- �ŵ��� �׸�ݾ�
    T_AF_BOOK_AMT NUMBER; -- �ŵ��� ��αݾ�
  BEGIN
    DBMS_OUTPUT.PUT_LINE('IN PR_SELL_BOND');
    -- 1. ä���ܰ� TABLE ��ȸ
    FOR C1 IN (SELECT A.*
                 FROM EVENT_RESULT_N_S_TKP A
                WHERE A.BOND_CODE = T_EVENT_INFO.BOND_CODE
                  AND A.BUY_DATE  = T_EVENT_INFO.BUY_DATE
                ORDER BY A.EVENT_DATE DESC, A.EVENT_SEQ DESC)
    LOOP
      T_EVENT_RESULT := C1;
      EXIT;
    END LOOP;
    
    -- 2. ���� ��LIST���� �ŵ��� �������� �״�� ����
    FOR IDX IN 1..T_EVENT_RESULT.SGF_LIST.COUNT LOOP
      T_SG_LIST.EXTEND;
      T_SG_LIST(T_SG_LIST.COUNT) := T_EVENT_RESULT.SGF_LIST(IDX);
      
      -- ��LIST ������� ���� �ŵ� �� �� ����
      IF TO_DATE(T_EVENT_RESULT.SGF_LIST(IDX).BASE_DATE, 'YYYYMMDD') < TO_DATE(T_EVENT_INFO.EVENT_DATE, 'YYYYMMDD') THEN
        T_BF_IDX := IDX;
      END IF;

    END LOOP;
    
    -- 3. �ŵ� ���ڵ� ����
    T_SG_ITEM := FN_INIT_SGF_TYPE_S(); -- INIT
    T_SG_ITEM.BASE_DATE := T_EVENT_INFO.EVENT_DATE;
    T_SG_ITEM.SEQ := FN_GET_SGF_SEQ(T_SG_ITEM.BASE_DATE, T_SG_LIST);
    T_SG_ITEM.SANGGAK_TYPE := T_EVENT_INFO.EVENT_TYPE;
    T_SG_LIST.EXTEND;
    T_SG_LIST(T_SG_LIST.COUNT) := T_SG_ITEM;
    
    -- 4. ��LIST ����
    PR_SORT_SANGGAK_FLOWS(T_SG_LIST);
    
    -- 5. ��LIST �����
    T_BF_SG_ITEM := T_SG_LIST(T_BF_IDX); -- ���󰢽�����
    T_REAL_INT_DATE := T_EVENT_INFO.BUY_DATE;
    T_BF_IDX := T_BF_IDX + 1;
    FOR I IN T_BF_IDX..T_SG_LIST.COUNT LOOP
      ----------�󰢾� ��ǥ----------
      IF I = T_BF_IDX+1 THEN
        T_AF_FACE_AMT := FN_ROUND(T_BF_SG_ITEM.FACE_AMT * (1 - T_EVENT_INFO.SELL_RT));
        T_AF_BOOK_AMT := FN_ROUND(T_BF_SG_ITEM.AF_BOOK_AMT * (1 - T_EVENT_INFO.SELL_RT));
        T_BF_SG_ITEM.FACE_AMT := FN_ROUND(T_BF_SG_ITEM.FACE_AMT * (1 - T_EVENT_INFO.SELL_RT));
        T_BF_SG_ITEM.AF_BOOK_AMT := FN_ROUND(T_BF_SG_ITEM.AF_BOOK_AMT * (1 - T_EVENT_INFO.SELL_RT));
        T_BF_SG_ITEM.AF_BOOK_AMT_EIR := FN_ROUND(T_BF_SG_ITEM.AF_BOOK_AMT_EIR * (1 - T_EVENT_INFO.SELL_RT));
      END IF;

      -- 1)�׸�ݾ�
      T_SG_LIST(I).FACE_AMT := FN_ROUND(T_BF_SG_ITEM.FACE_AMT);
      
      -- 2)���ϼ�(���󰢽������� �������� - ���󰢽������� ��������)
      T_SG_LIST(I).DAYS := FN_CALC_DAYS(T_BF_SG_ITEM.BASE_DATE, T_SG_LIST(I).BASE_DATE);
      
      ---------- ��ȿ���� ���� ----------
      -- ������αݾ�(���󰢽�����.�⸻��αݾ�)
      T_SG_LIST(I).BF_BOOK_AMT_EIR := T_BF_SG_ITEM.AF_BOOK_AMT_EIR;
      
      -- ��ȿ����(������αݾ�(EIR) * POWER(1 + EIR, ���ϼ�/365) -1))
      T_SG_LIST(I).EIR_INT_AMT := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT_EIR * (POWER(1+T_EVENT_RESULT.EIR, T_SG_LIST(I).DAYS/365) - 1));

      -- �����ڱݾ�(���������� OR �����Ͽ� ���� �߻��� �׸�����)
      IF I_EIR_C.BOND_TYPE = '1' THEN -- ��ǥä
        IF T_SG_LIST(I).SANGGAK_TYPE = '3' OR T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, FN_CALC_DAYS(T_REAL_INT_DATE, T_SG_LIST(I).BASE_DATE), T_SG_LIST(I).FACE_AMT, T_EVENT_RESULT.IR));
          T_REAL_INT_DATE := T_SG_LIST(I).BASE_DATE;
        END IF;
      ELSIF I_EIR_C.BOND_TYPE = '2' THEN -- ����ä
        T_SG_LIST(I).REAL_INT_AMT := 0;
      ELSIF I_EIR_C.BOND_TYPE = '3' THEN -- �ܸ�ä
        IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, FN_CALC_DAYS(T_REAL_INT_DATE, T_SG_LIST(I).BASE_DATE), T_SG_LIST(I).FACE_AMT, T_EVENT_RESULT.IR));
        END IF;
      ELSIF I_EIR_C.BOND_TYPE = '4' THEN -- ����ä
        IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_CPND_INT(I_EIR_C, T_BF_SG_ITEM.BASE_DATE, T_SG_LIST(I).BASE_DATE));
        END IF;
      END IF;
      
      -- �󰢱ݾ�(��ȿ���� - �����ڱݾ�)
      T_SG_LIST(I).SANGGAK_AMT_EIR := FN_ROUND(T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).REAL_INT_AMT);
      
      -- �⸻��αݾ�(������αݾ�(EIR) + �󰢾�(EIR))
      T_SG_LIST(I).AF_BOOK_AMT_EIR := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT_EIR + T_SG_LIST(I).SANGGAK_AMT_EIR);
      
      ----------�󰢾� ��ǥ----------
      -- 3)������αݾ�(���󰢽�����.�⸻��αݾ�)
      T_SG_LIST(I).BF_BOOK_AMT := T_BF_SG_ITEM.AF_BOOK_AMT;
      
      -- 4)�׸�����(�ǹ߻����� ������ �ƴ� �������)
      IF I_EIR_C.BOND_TYPE <> '4' THEN
        T_SG_LIST(I).FACE_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, T_SG_LIST(I).DAYS, T_SG_LIST(I).FACE_AMT, T_EVENT_RESULT.IR));
      ELSE
        -- �׸����� * ���ϼ� / ���ϼ�
        T_SG_LIST(I).FACE_INT_AMT := FN_ROUND(FN_GET_CAL_CPND_INT(I_EIR_C, I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE) * T_SG_LIST(I).DAYS / FN_CALC_DAYS(I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE));
      END IF;
      
      -- 5)�󰢾�(��ȿ���� - �׸�����)
      T_SG_LIST(I).SANGGAK_AMT := FN_ROUND(T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).FACE_INT_AMT);
      
      -- 6)�⸻��αݾ�(������αݾ� + �󰢾�)
      T_SG_LIST(I).AF_BOOK_AMT := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT + T_SG_LIST(I).SANGGAK_AMT);
      
      -- 7)�̻��ܾ�(�׸�ݾ� - �⸻��αݾ�)
      T_SG_LIST(I).MI_SANGGAK_AMT := FN_ROUND(T_SG_LIST(I).FACE_AMT - T_SG_LIST(I).AF_BOOK_AMT);
      
      
      -- �����Ͽ� �̻��ܾ��� 1�̻��̸� �ܼ����� ���� ���� �ƴ϶�, EIR�� ������ �ִ� ���̹Ƿ� ����ó��
--      IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
--        IF T_SG_LIST(I).MI_SANGGAK_AMT > 1 THEN
--          PCZ_RAISE(-20999, '�̻��ܾ��� 1�̻� ����(�̻��ܾ�:'||T_SG_LIST(I).MI_SANGGAK_AMT||')');
--        END IF;
--        
--        -- �������� ��ȿ���ڿ� ���� �̻��ܾ� ����ó��
--        IF T_SG_LIST(I).MI_SANGGAK_AMT <> 0 THEN
--          T_SG_LIST(I).EIR_INT_AMT := T_SG_LIST(I).EIR_INT_AMT + T_SG_LIST(I).MI_SANGGAK_AMT;
--          
--          T_SG_LIST(I).SANGGAK_AMT := T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).FACE_INT_AMT;
--          T_SG_LIST(I).AF_BOOK_AMT := T_SG_LIST(I).BF_BOOK_AMT + T_SG_LIST(I).SANGGAK_AMT;
--          T_SG_LIST(I).MI_SANGGAK_AMT := T_SG_LIST(I).FACE_AMT - T_SG_LIST(I).AF_BOOK_AMT;
--        END IF;
--      END IF;
      
      -- ����� ���� ���󰢽����� ����
      T_BF_SG_ITEM := T_SG_LIST(I);
    END LOOP;

    FOR I IN 1..T_SG_LIST.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(PKG_EIR_TKP_S.FN_GET_SANGGAK_FLOW_STR(T_SG_LIST(I)));
    END LOOP;
    
    
    DBMS_OUTPUT.PUT_LINE('--- INSERT(Event �������) ---');
    T_EVENT_INFO.IR := T_EVENT_RESULT.IR;
    T_EVENT_INFO.EIR := T_EVENT_RESULT.EIR;
    T_EVENT_INFO.FACE_AMT := T_AF_FACE_AMT;
    T_EVENT_INFO.BOOK_AMT := T_AF_BOOK_AMT;
    
    PKG_EIR_TKP_S.PR_INSERT_EVENT_RESULT_INFO(T_EVENT_INFO, T_EVENT_RESULT.CF_LIST, T_SG_LIST);
    
  END PR_SELL_BOND;

  
  
  -- INIT CF_TYPE_S
  FUNCTION FN_INIT_CF_TYPE_S RETURN CF_TYPE_S AS
  BEGIN
    RETURN NEW CF_TYPE_S(NULL, 0, 0, 0, 0, 0, 0);
  END;
  

  -- INIT SGF_TYPE_S
  FUNCTION FN_INIT_SGF_TYPE_S RETURN SGF_TYPE_S AS
  BEGIN
    RETURN NEW SGF_TYPE_S(NULL, 0, NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  END;
  

  -- FROM ~ TO �ϼ����
  FUNCTION FN_CALC_DAYS(I_FROM_DATE CHAR, I_TO_DATE CHAR)
    RETURN NUMBER AS
    T_DAYS NUMBER; -- ���� �ϼ�
  BEGIN
    T_DAYS := TO_DATE(I_TO_DATE,'YYYYMMDD') - TO_DATE(I_FROM_DATE,'YYYYMMDD');
    RETURN T_DAYS;
  END;


  -- ���ڹ߻�Ƚ�� ���
  FUNCTION FN_GET_INT_CNT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_INT_CNT NUMBER; -- ���ڹ߻�Ƚ��
    T_EVENT_DATE DATE := TO_DATE(I_EIR_C.EVENT_DATE, 'YYYYMMDD'); -- EVENT �߻��� (������)
    T_ISSUE_DATE DATE := TO_DATE(I_EIR_C.ISSUE_DATE, 'YYYYMMDD'); -- ������
  BEGIN
    T_INT_CNT := TRUNC(MONTHS_BETWEEN(T_EVENT_DATE, T_ISSUE_DATE) / I_EIR_C.INT_CYCLE);
    RETURN T_INT_CNT;
  END;


  -- �������������� ���
  FUNCTION FN_GET_BF_INT_DATE(I_EIR_C EIR_CALC_INFO)
    RETURN CHAR AS
    T_INT_CNT NUMBER; -- ���ڹ߻�Ƚ��
    T_BF_INT_DATE CHAR(8); -- ��������������
    T_EVENT_DATE DATE := TO_DATE(I_EIR_C.EVENT_DATE, 'YYYYMMDD'); -- EVENT �߻��� (������)
    T_ISSUE_DATE DATE := TO_DATE(I_EIR_C.ISSUE_DATE, 'YYYYMMDD'); -- ������
  BEGIN
    T_INT_CNT := TRUNC(MONTHS_BETWEEN(T_EVENT_DATE, T_ISSUE_DATE) / I_EIR_C.INT_CYCLE);
    T_BF_INT_DATE := TO_CHAR(ADD_MONTHS(T_ISSUE_DATE, T_INT_CNT*I_EIR_C.INT_CYCLE), 'YYYYMMDD');
    RETURN T_BF_INT_DATE;
  END;
  
  
  -- �������������� ���
  FUNCTION FN_GET_AF_INT_DATE(I_EIR_C EIR_CALC_INFO)
    RETURN CHAR AS
    T_INT_CNT NUMBER; -- ���ڹ߻�Ƚ��
    T_AF_INT_DATE CHAR(8); -- ��������������
    T_EVENT_DATE DATE := TO_DATE(I_EIR_C.EVENT_DATE, 'YYYYMMDD'); -- EVENT �߻��� (������)
    T_ISSUE_DATE DATE := TO_DATE(I_EIR_C.ISSUE_DATE, 'YYYYMMDD'); -- ������
  BEGIN
    T_INT_CNT := TRUNC(MONTHS_BETWEEN(T_EVENT_DATE, T_ISSUE_DATE) / I_EIR_C.INT_CYCLE);
    T_AF_INT_DATE := TO_CHAR(ADD_MONTHS(T_ISSUE_DATE, (T_INT_CNT+1)*I_EIR_C.INT_CYCLE), 'YYYYMMDD');
    RETURN T_AF_INT_DATE;
  END;


  -- �ݾ� ����
  FUNCTION FN_ROUND(I_NUM NUMBER)
    RETURN NUMBER AS
    T_AMT NUMBER; -- �ݾ�(���� �Ҽ�2�ڸ�)
  BEGIN
    T_AMT := TRUNC(I_NUM);
    RETURN T_AMT;
  END;
  
  FUNCTION FN_ROUND(I_NUM NUMBER, I_DIGITS NUMBER)
    RETURN NUMBER AS
    T_AMT NUMBER; -- �ݾ�(���� �Ҽ�2�ڸ�)
  BEGIN
    T_AMT := TRUNC(I_NUM, I_DIGITS);
    RETURN T_AMT;
  END;
  
  
  -- ���� SGF_LIST ���� EVENT���� �󰢽����� SEQ GET
  FUNCTION FN_GET_SGF_SEQ(I_BASE_DATE CHAR, I_SGF_LIST TABLE_SGF_S) RETURN NUMBER IS
    V_SEQ NUMBER := 1;
  BEGIN
    FOR IDX IN 1..I_SGF_LIST.COUNT LOOP
      IF I_BASE_DATE = I_SGF_LIST(IDX).BASE_DATE THEN
        V_SEQ := V_SEQ + 1;
      END IF;
    END LOOP;
    RETURN V_SEQ;
  END;


 FUNCTION FN_GET_EVENT_RESULT_NESTED_STR(I_EV_RET EVENT_RESULT_NESTED_S%ROWTYPE) RETURN VARCHAR2 IS
    V_STR VARCHAR2(1000);
  BEGIN
    V_STR :=   'ä���ڵ�['||I_EV_RET.BOND_CODE||']'      
             ||'�ż�����['||I_EV_RET.BUY_DATE||']'       
             ||'�̺�Ʈ��['||I_EV_RET.EVENT_DATE||']'     
             ||'����['||I_EV_RET.EVENT_SEQ||']'     
             ||'�̺�Ʈ����['||I_EV_RET.EVENT_TYPE||']'     
             ||'ǥ��������['||LPAD(I_EV_RET.IR, 10)||']'
             ||'��ȿ������['||LPAD(I_EV_RET.EIR,15)||']'
             ||'�ŵ���['||LPAD(I_EV_RET.SELL_RT, 5)||']'
             ||'�׸�ݾ�['||LPAD(I_EV_RET.FACE_AMT,10)||']'
             ||'��αݾ�['||LPAD(I_EV_RET.BOOK_AMT,10)||']';
    RETURN V_STR;
  END FN_GET_EVENT_RESULT_NESTED_STR;
  FUNCTION FN_GET_CASH_FLOW_STR(I_CF CF_TYPE_S) RETURN VARCHAR2 IS
    V_STR VARCHAR2(1000);
  BEGIN
    V_STR :=   '������['||I_CF.BASE_DATE||']'
             ||'�׸�['||LPAD(I_CF.FACE_AMT,10)||']'
             ||'���ϼ�['||LPAD(I_CF.TOT_DAYS,10)||']'
             ||'�����ϼ�['||LPAD(I_CF.INT_DAYS,10)||']'
             ||'���ڱݾ�['||LPAD(I_CF.INT_AMT,10)||']'
             ||'����['||LPAD(I_CF.PRC_AMT,10)||']'
             ||'���簡ġ['||LPAD(I_CF.CUR_VALUE,10)||']';
    RETURN V_STR;
  END FN_GET_CASH_FLOW_STR;
  FUNCTION FN_GET_SANGGAK_FLOW_STR(I_SGF SGF_TYPE_S) RETURN VARCHAR2 IS
    V_STR VARCHAR2(1000);
  BEGIN
    V_STR :=  '������['||I_SGF.BASE_DATE||']'       
            ||'SEQ['||I_SGF.SEQ||']'
            ||'TYPE['||I_SGF.SANGGAK_TYPE||']'
            ||'�ϼ�['||LPAD(I_SGF.DAYS,4)||']'            
            ||'�׸�['||LPAD(I_SGF.FACE_AMT,10)||']'        
            ||'�������['||LPAD(I_SGF.BF_BOOK_AMT,10)||']'     
            ||'��ȿ����['||LPAD(I_SGF.EIR_INT_AMT,10)||']'     
            ||'�׸�����['||LPAD(I_SGF.FACE_INT_AMT,10)||']'    
            ||'�󰢾�['||LPAD(I_SGF.SANGGAK_AMT,10)||']'     
            ||'�⸻���['||LPAD(I_SGF.AF_BOOK_AMT,10)||']'     
            ||'�̻󰢾�['||LPAD(I_SGF.MI_SANGGAK_AMT,10)||']'  
            ||'�������_E['||LPAD(I_SGF.BF_BOOK_AMT_EIR,10)||']' 
            ||'������['||LPAD(I_SGF.REAL_INT_AMT,10)||']'    
            ||'�󰢾�_E['||LPAD(I_SGF.SANGGAK_AMT_EIR,10)||']' 
            ||'�⸻���_E['||LPAD(I_SGF.AF_BOOK_AMT_EIR,10)||']';
     RETURN V_STR;       
  END FN_GET_SANGGAK_FLOW_STR;
  

END PKG_EIR_TKP_S;