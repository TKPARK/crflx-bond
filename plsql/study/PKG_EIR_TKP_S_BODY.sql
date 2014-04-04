CREATE OR REPLACE PACKAGE BODY ISS.PKG_EIR_TKP_S AS

  -- 경과이자 계산
  FUNCTION FN_CALC_ACCRUED_INT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_ACCRUED_INT NUMBER; -- 경과이자
  BEGIN
    IF I_EIR_C.BOND_TYPE = '1' THEN -- 1.이표채
      T_ACCRUED_INT := FN_GET_CPN_ACCRUED_INT(I_EIR_C);
    ELSIF I_EIR_C.BOND_TYPE = '2' THEN -- 2.할인채
      T_ACCRUED_INT := FN_GET_DISCNT_ACCRUED_INT(I_EIR_C);
    ELSIF I_EIR_C.BOND_TYPE = '3' THEN -- 3.단리채(만기일시)
      T_ACCRUED_INT := FN_GET_SIMPLE_ACCRUED_INT(I_EIR_C);
    ELSIF I_EIR_C.BOND_TYPE = '4' THEN -- 4.복리채
      T_ACCRUED_INT := FN_GET_CPND_ACCRUED_INT(I_EIR_C);
    END IF;
    
    -- OUTPUT
    --DBMS_OUTPUT.PUT_LINE('ACCRUED_INT=' || FN_ROUND(T_ACCRUED_INT));
    
    RETURN FN_ROUND(T_ACCRUED_INT);
  END;


  -- 경과이자 : 이표채(단리)(coupon bond)
  -- 액면금액 * 이자율 * (취득일 - 직전이자지급일) / 365
  FUNCTION FN_GET_CPN_ACCRUED_INT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_ACCRUED_INT NUMBER; -- 경과이자
    T_BF_INT_DATE CHAR(8); -- 직전이자지급일
    T_DAYS NUMBER; -- 일수
  BEGIN
    -- 1.직전이자지급일 계산
    T_BF_INT_DATE := FN_GET_BF_INT_DATE(I_EIR_C);
    
    -- 2.(취득일 - 직전이자지급일) 계산
    T_DAYS := FN_CALC_DAYS(T_BF_INT_DATE, I_EIR_C.EVENT_DATE);
    
    -- 3.경과이자 계산
    T_ACCRUED_INT := I_EIR_C.FACE_AMT * I_EIR_C.IR * T_DAYS / 365;
    RETURN T_ACCRUED_INT;
  END;
  
  
  -- 경과이자 : 할인채(discount debenture)
  FUNCTION FN_GET_DISCNT_ACCRUED_INT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_ACCRUED_INT NUMBER; -- 경과이자
  BEGIN
    T_ACCRUED_INT := 0;
    RETURN T_ACCRUED_INT;
  END;


  -- 경과이자 : 단리채(만기)(simple interest bond)
  -- 액면금액 * 이자율 * (취득일 - 발행일) / 365
  FUNCTION FN_GET_SIMPLE_ACCRUED_INT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_ACCRUED_INT NUMBER; -- 경과이자
    T_DAYS NUMBER; -- 일수
  BEGIN
    -- 1.(취득일 - 발행일) 계산
    T_DAYS := FN_CALC_DAYS(I_EIR_C.ISSUE_DATE, I_EIR_C.EVENT_DATE);
    
    -- 2.경과이자 계산
    T_ACCRUED_INT := I_EIR_C.FACE_AMT * I_EIR_C.IR * T_DAYS / 365;
    RETURN T_ACCRUED_INT;
  END;


  -- 경과이자 : 복리채(compound bond)
  -- 액면금액 * (1+IR/년지급횟수)^복리횟수
  -- ※복리횟수 = (발행일~직전이자기준일까지의 횟수) + (취득일-직전이자기준일) / (직후이자기준일-직전이자기준일)
  FUNCTION FN_GET_CPND_ACCRUED_INT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_ACCRUED_INT NUMBER; -- 경과이자
    T_CPND_BOND_CNT NUMBER; -- 복리횟수
    T_INT_CNT NUMBER; -- 이자발생횟수
    T_BF_INT_DATE CHAR(8); -- 직전이자지급일
    T_AF_INT_DATE CHAR(8); -- 직후이자지급일
  BEGIN
    -- 1.복리횟수 계산
    T_INT_CNT := FN_GET_INT_CNT(I_EIR_C);
    T_BF_INT_DATE := FN_GET_BF_INT_DATE(I_EIR_C);
    T_AF_INT_DATE := FN_GET_AF_INT_DATE(I_EIR_C);
    T_CPND_BOND_CNT := T_INT_CNT + FN_CALC_DAYS(T_BF_INT_DATE, I_EIR_C.EVENT_DATE) / FN_CALC_DAYS(T_BF_INT_DATE, T_AF_INT_DATE);
    
    -- 2.경과이자 계산
    T_ACCRUED_INT := I_EIR_C.FACE_AMT * POWER((1+I_EIR_C.IR/(12/I_EIR_C.INT_CYCLE)), T_CPND_BOND_CNT) - I_EIR_C.FACE_AMT;
        
    RETURN T_ACCRUED_INT;
  END;
  
  
  -- 이자 계산 : (1.이표채, 2.할인채, 3.단리채(만기일시))
  FUNCTION FN_GET_CAL_INT(BOND_TYPE CHAR, I_DAYS NUMBER, I_FACE_AMT NUMBER, I_IR NUMBER)
    RETURN NUMBER AS
    T_INT NUMBER; -- 이자
  BEGIN
    IF BOND_TYPE = '1' OR BOND_TYPE = '3' THEN
      T_INT := I_FACE_AMT * I_IR * I_DAYS / 365;
    ELSIF BOND_TYPE = '2' THEN
      T_INT := 0;
    END IF;
    RETURN T_INT;
  END;
  
  
  -- 이자 계산 : (4.복리채)
  FUNCTION FN_GET_CAL_CPND_INT(I_EIR_C EIR_CALC_INFO, I_BF_BASE_DATE CHAR, I_BASE_DATE CHAR)
    RETURN NUMBER AS
    T_BF_INT NUMBER; -- 전 이자
    T_INT NUMBER; -- 현 이자
    
    T_BF_EIR_C EIR_CALC_INFO := I_EIR_C; -- BEFORE
    T_EIR_C EIR_CALC_INFO := I_EIR_C; -- CURRENT
    
    T_CPND_BOND_CNT NUMBER; -- 복리횟수
    T_INT_CNT NUMBER; -- 이자발생횟수
    T_BF_INT_DATE CHAR(8); -- 직전이자지급일
    T_AF_INT_DATE CHAR(8); -- 직후이자지급일
  BEGIN
    -- 현 기준일자의 이자 계산 1.복리횟수 계산
    T_BF_EIR_C.EVENT_DATE := I_BASE_DATE;
    T_INT_CNT := FN_GET_INT_CNT(T_BF_EIR_C);
    T_BF_INT_DATE := FN_GET_BF_INT_DATE(T_BF_EIR_C);
    T_AF_INT_DATE := FN_GET_AF_INT_DATE(T_BF_EIR_C);
    T_CPND_BOND_CNT := T_INT_CNT + FN_CALC_DAYS(T_BF_INT_DATE, T_BF_EIR_C.EVENT_DATE) / FN_CALC_DAYS(T_BF_INT_DATE, T_AF_INT_DATE);
    -- 현 기준일자의 이자 계산 2.이자 계산
    T_INT := I_EIR_C.FACE_AMT * POWER((1+I_EIR_C.IR/(12/I_EIR_C.INT_CYCLE)), T_CPND_BOND_CNT) - I_EIR_C.FACE_AMT;

    -- 전 기준일자의 이자 계산 1.복리횟수 계산
    T_BF_EIR_C.EVENT_DATE := I_BF_BASE_DATE;
    T_INT_CNT := FN_GET_INT_CNT(I_EIR_C);
    T_BF_INT_DATE := FN_GET_BF_INT_DATE(I_EIR_C);
    T_AF_INT_DATE := FN_GET_AF_INT_DATE(I_EIR_C);
    T_CPND_BOND_CNT := T_INT_CNT + FN_CALC_DAYS(T_BF_INT_DATE, I_EIR_C.EVENT_DATE) / FN_CALC_DAYS(T_BF_INT_DATE, T_AF_INT_DATE);
    -- 전 기준일자의 이자 계산 2.이자 계산
    T_BF_INT := I_EIR_C.FACE_AMT * POWER((1+I_EIR_C.IR/(12/I_EIR_C.INT_CYCLE)), T_CPND_BOND_CNT) - I_EIR_C.FACE_AMT;
    
    -- 복리채 이자 = 현 이자 - 전 이자
    RETURN (T_INT-T_BF_INT);
  END;
  
  
  
  -- Cash Flow
  FUNCTION FN_CREATE_CASH_FLOWS (I_EIR_C EIR_CALC_INFO) 
    RETURN TABLE_CF_S AS
    T_INT_CYCLE NUMBER := I_EIR_C.INT_CYCLE; -- 이자주기(월)
    T_BF_BASE_DATE CHAR(8) := I_EIR_C.EVENT_DATE; -- 이전 현금흐름발생일(계산용)
    T_AF_INT_DATE DATE; -- 직후이자지급일
    T_EXPIRE_DATE DATE := TO_DATE(I_EIR_C.EXPIRE_DATE, 'YYYYMMDD'); -- 만기일
    T_CF_LIST TABLE_CF_S := NEW TABLE_CF_S(); -- Cash Flow LIST
    T_CF_ITEM CF_TYPE_S; -- Cash Flow ITEM
  BEGIN
    -- 취득정보
    T_CF_ITEM := FN_INIT_CF_TYPE_S(); -- INIT
    T_CF_ITEM.BASE_DATE := I_EIR_C.EVENT_DATE; -- 현금흐름발생일
    T_CF_LIST.EXTEND;
    T_CF_LIST(T_CF_LIST.COUNT) := T_CF_ITEM;

    -- 취득후 최초 이자 지급일 계산
    T_AF_INT_DATE := TO_DATE(FN_GET_AF_INT_DATE(I_EIR_C), 'YYYYMMDD');
    
    IF I_EIR_C.BOND_TYPE = '1' THEN -- [1.이표채]
      -- 직후이자지급일 ~ 만기일까지 CashFlow loop 실행
      WHILE T_EXPIRE_DATE >= T_AF_INT_DATE LOOP
        T_CF_ITEM := FN_INIT_CF_TYPE_S(); -- INIT
        T_CF_ITEM.BASE_DATE := TO_CHAR(T_AF_INT_DATE, 'YYYYMMDD'); -- 현금흐름발생일
        T_CF_ITEM.INT_DAYS := FN_CALC_DAYS(T_BF_BASE_DATE, TO_CHAR(T_AF_INT_DATE, 'YYYYMMDD')); -- 이자일수
        T_CF_ITEM.TOT_DAYS := FN_CALC_DAYS(I_EIR_C.EVENT_DATE, TO_CHAR(T_AF_INT_DATE, 'YYYYMMDD')); -- 총일수(기준일-취득일)
        T_CF_ITEM.INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, T_CF_ITEM.INT_DAYS, I_EIR_C.FACE_AMT, I_EIR_C.IR)); -- 이자금액
        
        -- 만기일에만 원금액 발생
        IF T_CF_ITEM.BASE_DATE = I_EIR_C.EXPIRE_DATE THEN
          T_CF_ITEM.PRC_AMT := I_EIR_C.FACE_AMT; -- 원금액
        END IF;
        
        T_CF_LIST.EXTEND;
        T_CF_LIST(T_CF_LIST.COUNT) := T_CF_ITEM;
        
        -- 다음 현금흐름발생일로 이동
        T_BF_BASE_DATE := TO_CHAR(T_AF_INT_DATE, 'YYYYMMDD');
        T_AF_INT_DATE := ADD_MONTHS(T_AF_INT_DATE, T_INT_CYCLE);
      END LOOP;
    ELSE -- [2.할인채, 3.단리채(만기일시), 4.복리채]
      T_CF_ITEM := FN_INIT_CF_TYPE_S(); -- INIT
      T_CF_ITEM.BASE_DATE := I_EIR_C.EXPIRE_DATE; -- 현금흐름발생일
      T_CF_ITEM.INT_DAYS := FN_CALC_DAYS(I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE); -- 이자일수
      T_CF_ITEM.TOT_DAYS := FN_CALC_DAYS(I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE); -- 총일수(기준일-취득일)
      IF I_EIR_C.BOND_TYPE = '4' THEN -- [4.복리채]
        T_CF_ITEM.INT_AMT := FN_ROUND(FN_GET_CAL_CPND_INT(I_EIR_C, T_BF_BASE_DATE, I_EIR_C.EXPIRE_DATE)); -- 이자금액
      ELSE
        T_CF_ITEM.INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, T_CF_ITEM.INT_DAYS, I_EIR_C.FACE_AMT, I_EIR_C.IR)); -- 이자금액
      END IF;
      
      -- 만기일에만 원금액 발생
      IF T_CF_ITEM.BASE_DATE = I_EIR_C.EXPIRE_DATE THEN
        T_CF_ITEM.PRC_AMT := I_EIR_C.FACE_AMT; -- 원금액
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
  
  
  -- EIR 찾기
  -- 1.최초 IR은 액면이자율을 IR, 가감단위는 최초 1%(0.01)으로 설정
  -- 2.근사값 EIR 찾기 함수 호출(Trial and error method)
  -- 3.리턴받은 근사값 EIR을 가지고 값 검증 실행
  -- 4.(현재가치의 합 - 취득금액) == 0 이면 loop를 빠져나온다
  --   0이 아니면 EIR를 IR로 재설정하고, 가감단위는 한단계 밑으로 내린후 -> 2.근사값 EIR 찾기 함수 호출
  FUNCTION FN_GET_EIR(I_EIR_C EIR_CALC_INFO, I_CF_LIST IN OUT TABLE_CF_S)
    RETURN NUMBER AS
    T_EIR NUMBER(15,10) := I_EIR_C.IR; -- 액면이자율 설정
    T_UNIT NUMBER := 0.01; -- 최초 1%(0.01)
    T_SUM_CV NUMBER := 0; -- 현재가치의 합
  BEGIN
    -- 소수 10자리까지 LOOP 실행
    FOR I IN 1..10 LOOP
      -- CALL 근사 EIR 찾기
      --DBMS_OUTPUT.PUT_LINE('---');
      --DBMS_OUTPUT.PUT_LINE('IN T_EIR='||T_EIR || ', T_UNIT='||T_UNIT);
      T_EIR := FN_GET_TRIAL_AND_ERROR(I_EIR_C, I_CF_LIST, T_EIR, T_UNIT);
      
      -- 값 검증
      T_SUM_CV := 0;
      FOR I IN 1..I_CF_LIST.COUNT LOOP
        -- 현재가치(Current Value) = 현금흐름합계 / POWER(1+EIR, 총일수/365)
        I_CF_LIST(I).CUR_VALUE := FN_ROUND((I_CF_LIST(I).PRC_AMT+I_CF_LIST(I).INT_AMT) / POWER(1+T_EIR, I_CF_LIST(I).TOT_DAYS/365));
        T_SUM_CV := T_SUM_CV + I_CF_LIST(I).CUR_VALUE;
      END LOOP;
      --DBMS_OUTPUT.PUT_LINE('OUT T_EIR='||T_EIR || ', T_SUM_CV='||T_SUM_CV);
      
      -- 현재가치의 합과 취득금액의 차이금액을 구함
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
  
  
  -- 근사 EIR 찾기
  -- 1.넘겨받은 IR(A)을 기준으로 현재가치(CV)의 합을 구함
  -- 2.차이금액 = 현재가치의 합 - 취득금액
  -- 3.차이금액 0 이상이면 increase
  --            0 이하이면 decrease
  -- 4.차이금액의 부호가 역전되는 시점의 IR(B)를 찾는다
  -- 5.IR(A), IR(B), 차이금액(A), 차이금액(B)를 가지고 Trial and error Method 공식으로 근사값 EIR를 찾아 리턴함
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
    -- A.현재가치의 합
    A_SUM_CV := 0;
    A_DIFF_AMT := 0;
    FOR I IN 1..I_CF_LIST.COUNT LOOP
      -- 현재가치(Current Value) = 현금흐름합계 / POWER(1+EIR, 총일수/365)
      A_SUM_CV := A_SUM_CV + FN_ROUND((I_CF_LIST(I).PRC_AMT+I_CF_LIST(I).INT_AMT) / POWER(1+A_IR, I_CF_LIST(I).TOT_DAYS/365));
    END LOOP;
    A_DIFF_AMT := A_SUM_CV - I_EIR_C.BOOK_AMT;
    --DBMS_OUTPUT.PUT_LINE('A_IR=' || A_IR || ', A_DIFF_AMT=' || A_DIFF_AMT);
    
    LOOP
      -- B.현재가치의 합
      IF SIGN(A_DIFF_AMT) = 1 THEN
        B_IR := B_IR + I_UNIT;
      ELSE
        B_IR := B_IR - I_UNIT;
      END IF;
      --DBMS_OUTPUT.PUT_LINE('B_IR=' || B_IR);
      
      B_SUM_CV := 0;
      FOR J IN 1..I_CF_LIST.COUNT LOOP
        -- 현재가치(Current Value) = 현금흐름합계 / POWER(1+EIR, 총일수/365)
        B_SUM_CV := B_SUM_CV + FN_ROUND((I_CF_LIST(J).PRC_AMT+I_CF_LIST(J).INT_AMT) / POWER(1+B_IR, I_CF_LIST(J).TOT_DAYS/365));
      END LOOP;
      B_DIFF_AMT := B_SUM_CV - I_EIR_C.BOOK_AMT;
      --DBMS_OUTPUT.PUT_LINE('A_DIFF_AMT='||A_DIFF_AMT||', B_DIFF_AMT='||B_DIFF_AMT);
      
      EXIT WHEN SIGN(A_DIFF_AMT) <> SIGN(B_DIFF_AMT);
    END LOOP;
    
    -- IR(A), IR(B)을 가지고 Trial and error Method 공식으로 근사값 계산
    T_EIR := TRUNC(A_IR+(B_IR-A_IR)*(A_DIFF_AMT/(A_DIFF_AMT-B_DIFF_AMT)), 10);
    RETURN T_EIR;
  END;
  
  
  -- 상각 테이블
  -- 1.상각리스트에 종류별 레코드 삽입(상각 TYPE : 1.매수, 2.매도, 3.이자수령, 4.만기, 5.월결산, 6.기결산, 7.손상, 8.회복)
  -- 2.생성된 상각리스트 정렬
  -- 3.상각액상각표 처리로직(상각일수 계산, 액면이자 계산, ..)
  FUNCTION FN_GET_SANG_GAK(I_EIR_C EIR_CALC_INFO, I_CF_LIST TABLE_CF_S)
    RETURN TABLE_SGF_S AS
    T_SG_LIST TABLE_SGF_S := NEW TABLE_SGF_S();
    T_SG_ITEM SGF_TYPE_S; -- 현재상각스케쥴
    T_BF_SG_ITEM SGF_TYPE_S; -- 전상각스케쥴
    T_LAST_MONTE_DATE DATE := TO_CHAR(LAST_DAY(I_EIR_C.EVENT_DATE), 'YYYYMMDD'); -- 취득일
    T_EXPIRE_DATE DATE := TO_DATE(I_EIR_C.EXPIRE_DATE, 'YYYYMMDD'); -- 만기일
    T_AF_INT_DATE DATE;
    T_REAL_INT_DATE CHAR(8);
  BEGIN
    -- 1-1.레코드 삽입(매수)
    T_SG_ITEM := FN_INIT_SGF_TYPE_S(); -- INIT
    T_SG_ITEM.BASE_DATE := I_EIR_C.EVENT_DATE; -- EVENT 발생일 (기준일)
    T_SG_ITEM.SEQ := FN_GET_SGF_SEQ(T_SG_ITEM.BASE_DATE, T_SG_LIST);
    T_SG_ITEM.SANGGAK_TYPE := '1'; -- 1.매수
    T_SG_LIST.EXTEND;
    T_SG_LIST(T_SG_LIST.COUNT) := T_SG_ITEM;
    
    -- 1-2.레코드 삽입(이자수령)
    IF I_EIR_C.BOND_TYPE = '1' THEN -- 이표채
      T_AF_INT_DATE := TO_DATE(FN_GET_AF_INT_DATE(I_EIR_C), 'YYYYMMDD'); -- 취득후 최초 이자 지급일 계산
      WHILE T_EXPIRE_DATE > T_AF_INT_DATE LOOP -- 직후이자지급일 ~ 만기일까지
        T_SG_ITEM := FN_INIT_SGF_TYPE_S(); -- INIT
        T_SG_ITEM.BASE_DATE := TO_CHAR(T_AF_INT_DATE, 'YYYYMMDD');
        T_SG_ITEM.SEQ := FN_GET_SGF_SEQ(T_SG_ITEM.BASE_DATE, T_SG_LIST);
        T_SG_ITEM.SANGGAK_TYPE := '3'; -- 3.이자수령
        T_SG_LIST.EXTEND;
        T_SG_LIST(T_SG_LIST.COUNT) := T_SG_ITEM;
      
        T_AF_INT_DATE := ADD_MONTHS(T_AF_INT_DATE, I_EIR_C.INT_CYCLE);
      END LOOP;
  END IF;

    -- 1-3.레코드 삽입(월결산)
    WHILE T_EXPIRE_DATE > T_LAST_MONTE_DATE LOOP -- 취득일 ~ 만기일까지
      T_SG_ITEM := FN_INIT_SGF_TYPE_S(); -- INIT
      T_SG_ITEM.BASE_DATE := TO_CHAR(T_LAST_MONTE_DATE, 'YYYYMMDD');
      T_SG_ITEM.SEQ := FN_GET_SGF_SEQ(T_SG_ITEM.BASE_DATE, T_SG_LIST);
      IF TO_CHAR(T_LAST_MONTE_DATE, 'MM') = '12' THEN
        T_SG_ITEM.SANGGAK_TYPE := '6'; -- 6.기결산
      ELSE
        T_SG_ITEM.SANGGAK_TYPE := '5'; -- 5.월결산
      END IF;
      
      T_SG_LIST.EXTEND;
      T_SG_LIST(T_SG_LIST.COUNT) := T_SG_ITEM;
  
      T_LAST_MONTE_DATE := LAST_DAY(ADD_MONTHS(T_LAST_MONTE_DATE, 1));
    END LOOP;

    -- 1-4.레코드 삽입(만기)
    T_SG_ITEM := FN_INIT_SGF_TYPE_S(); -- INIT
    T_SG_ITEM.BASE_DATE := I_EIR_C.EXPIRE_DATE;
    T_SG_ITEM.SEQ := FN_GET_SGF_SEQ(T_SG_ITEM.BASE_DATE, T_SG_LIST);
    T_SG_ITEM.SANGGAK_TYPE := '4'; -- 4:만기
    T_SG_LIST.EXTEND;
    T_SG_LIST(T_SG_LIST.COUNT) := T_SG_ITEM;
    

    -- 2.상각리스트 정렬
    --PR_QUICK_SORT(T_SG_LIST, 1, T_SG_LIST.COUNT);
    PR_SORT_SANGGAK_FLOWS(T_SG_LIST);

    
    -- 3.상각액상각표 처리로직
    T_BF_SG_ITEM := T_SG_LIST(1); -- 전상각스케쥴
    T_BF_SG_ITEM.FACE_AMT := I_EIR_C.FACE_AMT; -- 액면금액
    T_BF_SG_ITEM.AF_BOOK_AMT := I_EIR_C.BOOK_AMT; -- 장부금액
    T_BF_SG_ITEM.AF_BOOK_AMT_EIR := I_EIR_C.BOOK_AMT; -- 장부금액
    T_REAL_INT_DATE := I_EIR_C.EVENT_DATE;
    FOR I IN 1..T_SG_LIST.COUNT LOOP
      ----------상각액 상각표----------
      -- 1)액면금액
      T_SG_LIST(I).FACE_AMT := FN_ROUND(T_BF_SG_ITEM.FACE_AMT);
      
      -- 2)상각일수(현상각스케쥴의 기준일자 - 전상각스케쥴의 기준일자)
      T_SG_LIST(I).DAYS := FN_CALC_DAYS(T_BF_SG_ITEM.BASE_DATE, T_SG_LIST(I).BASE_DATE);
      
      ---------- 유효이자 계산용 ----------
      -- 기초장부금액(전상각스케쥴.기말장부금액)
      T_SG_LIST(I).BF_BOOK_AMT_EIR := T_BF_SG_ITEM.AF_BOOK_AMT_EIR;
      
      -- 유효이자(기초장부금액(EIR) * POWER(1 + EIR, 상각일수/365) -1))
      T_SG_LIST(I).EIR_INT_AMT := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT_EIR * (POWER(1+I_EIR_C.EIR, T_SG_LIST(I).DAYS/365) - 1));

      -- 실이자금액(이자지급일 OR 만기일에 실제 발생한 액면이자)
      IF I_EIR_C.BOND_TYPE = '1' THEN -- 이표채
        IF T_SG_LIST(I).SANGGAK_TYPE = '3' OR T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, FN_CALC_DAYS(T_REAL_INT_DATE, T_SG_LIST(I).BASE_DATE), T_SG_LIST(I).FACE_AMT, I_EIR_C.IR));
          T_REAL_INT_DATE := T_SG_LIST(I).BASE_DATE;
        END IF;
      ELSIF I_EIR_C.BOND_TYPE = '2' THEN -- 할인채
        T_SG_LIST(I).REAL_INT_AMT := 0;
      ELSIF I_EIR_C.BOND_TYPE = '3' THEN -- 단리채
        IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, FN_CALC_DAYS(T_REAL_INT_DATE, T_SG_LIST(I).BASE_DATE), T_SG_LIST(I).FACE_AMT, I_EIR_C.IR));
          T_REAL_INT_DATE := T_SG_LIST(I).BASE_DATE;
        END IF;
      ELSIF I_EIR_C.BOND_TYPE = '4' THEN -- 복리채
        IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_CPND_INT(I_EIR_C, T_BF_SG_ITEM.BASE_DATE, T_SG_LIST(I).BASE_DATE));
        END IF;
      END IF;
      
      -- 상각금액(유효이자 - 실이자금액)
      T_SG_LIST(I).SANGGAK_AMT_EIR := FN_ROUND(T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).REAL_INT_AMT);
      
      -- 기말장부금액(기초장부금액(EIR) + 상각액(EIR))
      T_SG_LIST(I).AF_BOOK_AMT_EIR := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT_EIR + T_SG_LIST(I).SANGGAK_AMT_EIR);
      
      ----------상각액 상각표----------
      -- 3)기초장부금액(전상각스케쥴.기말장부금액)
      T_SG_LIST(I).BF_BOOK_AMT := T_BF_SG_ITEM.AF_BOOK_AMT;
      
      -- 4)액면이자(실발생이자 기준이 아닌 계산이자)
      IF I_EIR_C.BOND_TYPE <> '4' THEN
        T_SG_LIST(I).FACE_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, T_SG_LIST(I).DAYS, T_SG_LIST(I).FACE_AMT, I_EIR_C.IR));
      ELSE
        -- 액면이자 * 상각일수 / 총일수
        T_SG_LIST(I).FACE_INT_AMT := FN_ROUND(FN_GET_CAL_CPND_INT(I_EIR_C, I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE) * T_SG_LIST(I).DAYS / FN_CALC_DAYS(I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE));
      END IF;
      
      -- 5)상각액(유효이자 - 액면이자)
      T_SG_LIST(I).SANGGAK_AMT := FN_ROUND(T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).FACE_INT_AMT);
      
      -- 6)기말장부금액(기초장부금액 + 상각액)
      T_SG_LIST(I).AF_BOOK_AMT := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT + T_SG_LIST(I).SANGGAK_AMT);
      
      -- 7)미상각잔액(액면금액 - 기말장부금액)
      T_SG_LIST(I).MI_SANGGAK_AMT := FN_ROUND(T_SG_LIST(I).FACE_AMT - T_SG_LIST(I).AF_BOOK_AMT);
      
      
      -- 만기일에 미상각잔액이 1이상이면 단수차에 의한 것이 아니라, EIR에 문제가 있는 것이므로 오류처리
--      IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
--        IF T_SG_LIST(I).MI_SANGGAK_AMT > 1 THEN
--          PCZ_RAISE(-20999, '미상각잔액이 1이상 차이(미상각잔액:'||T_SG_LIST(I).MI_SANGGAK_AMT||')');
--        END IF;
--        
--        -- 만기일의 유효이자에 남은 미상각잔액 보정처리
--        IF T_SG_LIST(I).MI_SANGGAK_AMT <> 0 THEN
--          T_SG_LIST(I).EIR_INT_AMT := T_SG_LIST(I).EIR_INT_AMT + T_SG_LIST(I).MI_SANGGAK_AMT;
--          
--          T_SG_LIST(I).SANGGAK_AMT := T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).FACE_INT_AMT;
--          T_SG_LIST(I).AF_BOOK_AMT := T_SG_LIST(I).BF_BOOK_AMT + T_SG_LIST(I).SANGGAK_AMT;
--          T_SG_LIST(I).MI_SANGGAK_AMT := T_SG_LIST(I).FACE_AMT - T_SG_LIST(I).AF_BOOK_AMT;
--        END IF;
--      END IF;
      
      
      -- 계산을 위한 전상각스케쥴 저장
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
  
  
  -- Sort SangGak Flow List (기준일기준 ASC) Bubble Sort 기준
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
        -- 기준일비교 Swap 
        IF V_SGF_1.BASE_DATE > V_SGF_2.BASE_DATE THEN
          V_SG_TEMP           := O_SGF_LIST(I_IDX);
          O_SGF_LIST(I_IDX)   := O_SGF_LIST(I_IDX-1);
          O_SGF_LIST(I_IDX-1) := V_SG_TEMP;
          V_SWAPPED := TRUE;    
        ELSIF V_SGF_1.BASE_DATE = V_SGF_2.BASE_DATE AND V_SGF_1.SEQ > V_SGF_2.SEQ THEN -- <EVENT_SEQ> 동일 기준일이면 SEQ 기준 Swap
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
  
  
  -- 채번(Event 결과정보 EVENT_SEQ)
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
  
 
  -- 채번(잔고 BALAN_SEQ)
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
  
  
  -- 채번(거래내역 TRD_SEQ)
  FUNCTION FN_GET_TRD_SEQ(I_EVENT_INFO EVENT_INFO_TYPE) RETURN NUMBER IS
    T_TRD_SEQ NUMBER := 0;
  BEGIN
  
    SELECT NVL(MAX(TRD_SEQ), 0) + 1 AS SEQ
      INTO T_TRD_SEQ
      FROM BOND_TRADE
     WHERE TRD_DATE = I_EVENT_INFO.EVENT_DATE;
       
    RETURN T_TRD_SEQ;
  END;

  
  -- INSERT(Event 결과정보)
  PROCEDURE PR_INSERT_EVENT_RESULT_INFO(I_EVENT_INFO EVENT_INFO_TYPE, I_CF_LIST TABLE_CF_S, I_SG_LIST TABLE_SGF_S) IS
    T_EVENT_SEQ NUMBER := 0; -- 이벤트 SEQ
  BEGIN
    -- 이벤트 SEQ 채번
    T_EVENT_SEQ := PKG_EIR_TKP_S.FN_GET_EVENT_SEQ(I_EVENT_INFO);
    
    INSERT INTO ISS.EVENT_RESULT_N_S_TKP VALUES (
      I_EVENT_INFO.BOND_CODE -- Bond Code(채권잔고의 PK)                                                 
    , I_EVENT_INFO.BUY_DATE -- Buy Date (채권잔고의 PK)                                                 
    , I_EVENT_INFO.EVENT_DATE -- 이벤트일 (PK)                                                            
    , T_EVENT_SEQ -- 이벤트 SEQ (PK : 동일한 EVENT일에 2개이상의 동일한 EVENT 발생시를 고려함)
    , I_EVENT_INFO.EVENT_TYPE -- Event 종류 : 1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복                  
    , I_EVENT_INFO.IR -- 표면이자율                                                               
    , I_EVENT_INFO.EIR -- 유효이자율                                                               
    , I_EVENT_INFO.SELL_RT -- 매도율                                                                   
    , I_EVENT_INFO.FACE_AMT -- 액면금액                                                                 
    , I_EVENT_INFO.BOOK_AMT -- 장부금액                                                                 
    , I_CF_LIST -- Cash Flow List                                                           
    , I_SG_LIST -- SangGakFlow List                                                         
    );
    
    --COMMIT
    DBMS_OUTPUT.PUT_LINE('SUCCESS(EVENT_RESULT_N_S_TKP)');
    
  END PR_INSERT_EVENT_RESULT_INFO;
  
  
  -- INSERT(잔고)
  PROCEDURE PR_INSERT_BOND_BALANCE(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO, I_ACCRUED_INT NUMBER) IS
    T_BOND_BALANCE BOND_BALANCE%ROWTYPE; -- 잔고 ROWTYPE
    T_BOND_TRADE BOND_TRADE%ROWTYPE;     -- 거래내역 ROWTYPE
    T_TRD_PRICE      NUMBER := (I_EVENT_INFO.BOOK_AMT + I_ACCRUED_INT) / 10000; -- 거래단가
    T_TRD_QTY        NUMBER := I_EVENT_INFO.FACE_AMT / 1000;                    -- 거래수량
    T_TRD_FACE_AMT   NUMBER := T_TRD_QTY * 1000;                                -- 거래액면(거래수량 * 1000)
    T_TRD_AMT        NUMBER := T_TRD_PRICE * T_TRD_QTY / 10;                    -- 거래금액(거래단가 * 거래수량 / 10)
    T_BOOK_AMT       NUMBER := T_TRD_AMT - I_ACCRUED_INT;                       -- 장부금액(= 거래금액 - 경과이자)
    T_BOOK_PRC_AMT   NUMBER := T_TRD_AMT - I_ACCRUED_INT;                       -- 장부원가(= 거래금액 - 경과이자)
    T_MI_SANGGAK_AMT NUMBER := T_TRD_FACE_AMT - T_BOOK_AMT;                     -- 미상각금액(= 거래액면 - 장부금액)
  BEGIN
    /* 잔고 TABLE */
    -- PK
    T_BOND_BALANCE.BIZ_DATE        := I_EVENT_INFO.EVENT_DATE;                        -- 영업일자
    T_BOND_BALANCE.FUND_CODE       := I_EVENT_INFO.BOND_CODE;                         -- 펀드코드
    T_BOND_BALANCE.BOND_CODE       := I_EVENT_INFO.BOND_CODE;                         -- 종목코드
    T_BOND_BALANCE.BUY_DATE        := I_EVENT_INFO.BUY_DATE;                          -- 매수일자
    T_BOND_BALANCE.BUY_PRICE       := T_TRD_PRICE;                                    -- 매수단가
    T_BOND_BALANCE.BALAN_SEQ       := PKG_EIR_TKP_S.FN_GET_BALAN_SEQ(T_BOND_BALANCE); -- 잔고일련번호
    
    -- VALUE
    T_BOND_BALANCE.BOND_IR         := I_EVENT_INFO.IR;                                -- IR
    T_BOND_BALANCE.BOND_EIR        := I_EVENT_INFO.EIR;                               -- EIR
    T_BOND_BALANCE.TOT_QTY         := T_TRD_QTY;                                      -- 총잔고수량
    T_BOND_BALANCE.TDY_AVAL_QTY    := T_TRD_QTY;                                      -- 당일가용수량
    T_BOND_BALANCE.NDY_AVAL_QTY    := T_TRD_QTY;                                      -- 익일가용수량
    T_BOND_BALANCE.BOOK_AMT        := T_BOOK_AMT;                                     -- 장부금액
    T_BOND_BALANCE.BOOK_PRC_AMT    := T_BOOK_PRC_AMT;                                 -- 장부원가
    T_BOND_BALANCE.ACCRUED_INT     := I_ACCRUED_INT;                                  -- 경과이자
    T_BOND_BALANCE.BTRM_UNPAID_INT := 0;                                              -- 전기미수이자
    T_BOND_BALANCE.TTRM_BOND_INT   := 0;                                              -- 당기채권이자
    T_BOND_BALANCE.SANGGAK_AMT     := 0;                                              -- 상각금액(상각이자)
    T_BOND_BALANCE.MI_SANGGAK_AMT  := T_MI_SANGGAK_AMT;                               -- 미상각금액(미상각이자)
    T_BOND_BALANCE.TRD_PRFT        := 0;                                              -- 매매이익
    T_BOND_BALANCE.TRD_LOSS        := 0;                                              -- 매매손실
    T_BOND_BALANCE.BTRM_EVAL_PRFT  := 0;                                              -- 전기평가이익
    T_BOND_BALANCE.BTRM_EVAL_LOSS  := 0;                                              -- 전기평가손실
    T_BOND_BALANCE.EVAL_PRICE      := 0;                                              -- 평가단가
    T_BOND_BALANCE.EVAL_AMT        := 0;                                              -- 평가금액
    T_BOND_BALANCE.TOT_EVAL_PRFT   := 0;                                              -- 누적평가이익
    T_BOND_BALANCE.TOT_EVAL_LOSS   := 0;                                              -- 누적평가손실
    T_BOND_BALANCE.TTRM_EVAL_PRFT  := 0;                                              -- 당기평가이익
    T_BOND_BALANCE.TTRM_EVAL_LOSS  := 0;                                              -- 당기평가손실
    T_BOND_BALANCE.AQST_QTY        := 0;                                              -- 인수수량
    T_BOND_BALANCE.DRT_SELL_QTY    := 0;                                              -- 직매도수량
    T_BOND_BALANCE.DRT_BUY_QTY     := T_TRD_QTY;                                      -- 직매수수량
    T_BOND_BALANCE.TXSTD_AMT       := 0;                                              -- 과표금액
    T_BOND_BALANCE.CORP_TAX        := 0;                                              -- 선급법인세
    T_BOND_BALANCE.UNPAID_CORP_TAX := 0;                                              -- 미지급법인세    
    
    
    -- COMMIT
    INSERT INTO ISS.BOND_BALANCE VALUES T_BOND_BALANCE;
    DBMS_OUTPUT.PUT_LINE('SUCCESS(BOND_BALANCE)');
    
    /* 거래내역 TABLE */
     -- PK
    T_BOND_TRADE.TRD_DATE            := I_EVENT_INFO.EVENT_DATE;                    -- 거래일자
    T_BOND_TRADE.TRD_SEQ             := PKG_EIR_TKP_S.FN_GET_TRD_SEQ(I_EVENT_INFO); -- 거래일련번호
    
    -- VALUE
    T_BOND_TRADE.FUND_CODE           := T_BOND_BALANCE.FUND_CODE;                   -- 펀드코드
    T_BOND_TRADE.BOND_CODE           := T_BOND_BALANCE.BOND_CODE;                   -- 종목코드
    T_BOND_TRADE.BUY_DATE            := T_BOND_BALANCE.BUY_DATE;                    -- 매수일자
    T_BOND_TRADE.BUY_PRICE           := T_BOND_BALANCE.BUY_PRICE;                   -- 매수단가
    T_BOND_TRADE.BALAN_SEQ           := T_BOND_BALANCE.BALAN_SEQ;                   -- 잔고일련번호
    T_BOND_TRADE.TRD_TYPE_CD         := '2';                                        -- 매매유형코드(1.인수,2.직매수,3.직매도,4.상환)
    T_BOND_TRADE.GOODS_BUY_SELL_SECT := '1';                                        -- 상품매수매도구분(1.상품매수,2.상품매도)
    T_BOND_TRADE.STT_TERM_SECT       := '0';                                        -- 결제기간구분(0.당일,1.익일,2.선도(지정일))
    T_BOND_TRADE.SETL_DATE           := I_EIR_C.EVENT_DATE;                         -- 결제일자
    T_BOND_TRADE.EXPR_DATE           := I_EIR_C.EXPIRE_DATE;                        -- 만기일자
    T_BOND_TRADE.TRD_PRICE           := T_TRD_PRICE;                                -- 매매단가
    T_BOND_TRADE.TRD_QTY             := T_TRD_QTY;                                  -- 매매수량
    T_BOND_TRADE.TRD_FACE_AMT        := T_TRD_FACE_AMT;                             -- 매매액면
    T_BOND_TRADE.TRD_AMT             := T_TRD_AMT;                                  -- 매매금액
    T_BOND_TRADE.TRD_NET_AMT         := T_BOOK_AMT;                                 -- 매매정산금액
    T_BOND_TRADE.TOT_INT             := I_ACCRUED_INT;                              -- 총이자금액
    T_BOND_TRADE.ACCRUED_INT         := I_ACCRUED_INT;                              -- 경과이자
    T_BOND_TRADE.BTRM_UNPAID_INT     := 0;                                          -- 전기미수이자
    T_BOND_TRADE.TTRM_BOND_INT       := 0;                                          -- 당기채권이자
    T_BOND_TRADE.TOT_DCNT            := 0;                                          -- 총일수
    T_BOND_TRADE.SRV_DCNT            := 0;                                          -- 잔존일수
    T_BOND_TRADE.LPCNT               := 0;                                          -- 경과일수
    T_BOND_TRADE.HOLD_DCNT           := 0;                                          -- 보유일수
    T_BOND_TRADE.BOND_EIR            := I_EVENT_INFO.EIR;                           -- 유효이자율
    T_BOND_TRADE.BOND_IR             := I_EVENT_INFO.IR;                            -- 표면이자율
    T_BOND_TRADE.SANGGAK_AMT         := 0;                                          -- 상각금액
    T_BOND_TRADE.MI_SANGGAK_AMT      := 0;                                          -- 미상각금액
    T_BOND_TRADE.BOOK_AMT            := T_BOOK_AMT;                                 -- 장부금액
    T_BOND_TRADE.BOOK_PRC_AMT        := T_BOOK_PRC_AMT;                             -- 장부원가
    T_BOND_TRADE.TRD_PRFT            := 0;                                          -- 매매이익
    T_BOND_TRADE.TRD_LOSS            := 0;                                          -- 매매손실
    T_BOND_TRADE.BTRM_EVAL_PRFT      := 0;                                          -- 전기평가이익
    T_BOND_TRADE.BTRM_EVAL_LOSS      := 0;                                          -- 전기평가손실
    T_BOND_TRADE.TXSTD_AMT           := 0;                                          -- 과표금액
    T_BOND_TRADE.CORP_TAX            := 0;                                          -- 선급법인세
    T_BOND_TRADE.UNPAID_CORP_TAX     := 0;                                          -- 미지급법인세
    
    
    --COMMIT
    INSERT INTO ISS.BOND_TRADE VALUES T_BOND_TRADE;
    DBMS_OUTPUT.PUT_LINE('SUCCESS(BOND_TRADE)');

    
  END PR_INSERT_BOND_BALANCE;
  
  
  -- INSERT(거래내역)
  PROCEDURE PR_INSERT_BOND_TRADE(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO, I_ACCRUED_INT NUMBER) IS
    T_BOND_TRADE BOND_TRADE%ROWTYPE; -- 거래내역 ROWTYPE
  BEGIN
    -- PK
    T_BOND_TRADE.TRD_DATE := I_EVENT_INFO.EVENT_DATE; -- 거래일자
    T_BOND_TRADE.TRD_SEQ := PKG_EIR_TKP_S.FN_GET_TRD_SEQ(I_EVENT_INFO); -- 거래일련번호
    
    --COMMIT
    INSERT INTO ISS.BOND_TRADE VALUES T_BOND_TRADE;
    DBMS_OUTPUT.PUT_LINE('SUCCESS');
  END PR_INSERT_BOND_TRADE;
 
  
  -- 채권 신규 매수
  PROCEDURE PR_NEW_BUY_BOND(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO) IS
    T_EVENT_INFO EVENT_INFO_TYPE := I_EVENT_INFO; -- EVENT INFO
    T_EIR_C EIR_CALC_INFO := I_EIR_C; -- EIR CALC INFO
    T_ACCRUED_INT NUMBER := 0; -- 경과이자
    T_CF_LIST TABLE_CF_S := NEW TABLE_CF_S(); -- Cash Flow LIST
    T_SG_LIST TABLE_SGF_S := NEW TABLE_SGF_S(); -- 상각 LIST
  BEGIN
    DBMS_OUTPUT.PUT_LINE('--- 경과이자 ---');
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
    
    DBMS_OUTPUT.PUT_LINE('--- 상각테이블 ---');
    T_SG_LIST := PKG_EIR_TKP_S.FN_GET_SANG_GAK(T_EIR_C, T_CF_LIST);
    FOR I IN 1..T_SG_LIST.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(PKG_EIR_TKP_S.FN_GET_SANGGAK_FLOW_STR(T_SG_LIST(I)));
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('--- INSERT(Event 결과정보) ---');
    PKG_EIR_TKP_S.PR_INSERT_EVENT_RESULT_INFO(T_EVENT_INFO, T_CF_LIST, T_SG_LIST);
    
    DBMS_OUTPUT.PUT_LINE('--- INSERT(잔고) ---');
    PKG_EIR_TKP_S.PR_INSERT_BOND_BALANCE(T_EVENT_INFO, T_EIR_C, T_ACCRUED_INT);
    
    --DBMS_OUTPUT.PUT_LINE('--- INSERT(거래내역) ---');
    --PKG_EIR_TKP_S.PR_INSERT_BOND_TRADE(T_EVENT_INFO, T_EIR_C, T_ACCRUED_INT);

    
  END PR_NEW_BUY_BOND;
  
  
  -- 채권 분할 매도
  PROCEDURE PR_SELL_BOND(I_EVENT_INFO EVENT_INFO_TYPE, I_EIR_C EIR_CALC_INFO) IS
    T_EVENT_RESULT EVENT_RESULT_NESTED_S%ROWTYPE;
    T_EVENT_INFO EVENT_INFO_TYPE := I_EVENT_INFO; -- EVENT INFO
    T_SG_LIST TABLE_SGF_S := NEW TABLE_SGF_S(); -- 상각 LIST
    T_SG_ITEM SGF_TYPE_S; -- 현재상각스케쥴
    T_BF_SG_ITEM SGF_TYPE_S; -- 전상각스케쥴
    T_BF_IDX NUMBER;
    T_REAL_INT_DATE CHAR(8);
    T_AF_FACE_AMT NUMBER; -- 매도후 액면금액
    T_AF_BOOK_AMT NUMBER; -- 매도후 장부금액
  BEGIN
    DBMS_OUTPUT.PUT_LINE('IN PR_SELL_BOND');
    -- 1. 채권잔고 TABLE 조회
    FOR C1 IN (SELECT A.*
                 FROM EVENT_RESULT_N_S_TKP A
                WHERE A.BOND_CODE = T_EVENT_INFO.BOND_CODE
                  AND A.BUY_DATE  = T_EVENT_INFO.BUY_DATE
                ORDER BY A.EVENT_DATE DESC, A.EVENT_SEQ DESC)
    LOOP
      T_EVENT_RESULT := C1;
      EXIT;
    END LOOP;
    
    -- 2. 기존 상각LIST에서 매도일 이전것은 그대로 저장
    FOR IDX IN 1..T_EVENT_RESULT.SGF_LIST.COUNT LOOP
      T_SG_LIST.EXTEND;
      T_SG_LIST(T_SG_LIST.COUNT) := T_EVENT_RESULT.SGF_LIST(IDX);
      
      -- 상각LIST 재산출을 위해 매도 전 상각 저장
      IF TO_DATE(T_EVENT_RESULT.SGF_LIST(IDX).BASE_DATE, 'YYYYMMDD') < TO_DATE(T_EVENT_INFO.EVENT_DATE, 'YYYYMMDD') THEN
        T_BF_IDX := IDX;
      END IF;

    END LOOP;
    
    -- 3. 매도 레코드 삽입
    T_SG_ITEM := FN_INIT_SGF_TYPE_S(); -- INIT
    T_SG_ITEM.BASE_DATE := T_EVENT_INFO.EVENT_DATE;
    T_SG_ITEM.SEQ := FN_GET_SGF_SEQ(T_SG_ITEM.BASE_DATE, T_SG_LIST);
    T_SG_ITEM.SANGGAK_TYPE := T_EVENT_INFO.EVENT_TYPE;
    T_SG_LIST.EXTEND;
    T_SG_LIST(T_SG_LIST.COUNT) := T_SG_ITEM;
    
    -- 4. 상각LIST 정렬
    PR_SORT_SANGGAK_FLOWS(T_SG_LIST);
    
    -- 5. 상각LIST 재산출
    T_BF_SG_ITEM := T_SG_LIST(T_BF_IDX); -- 전상각스케쥴
    T_REAL_INT_DATE := T_EVENT_INFO.BUY_DATE;
    T_BF_IDX := T_BF_IDX + 1;
    FOR I IN T_BF_IDX..T_SG_LIST.COUNT LOOP
      ----------상각액 상각표----------
      IF I = T_BF_IDX+1 THEN
        T_AF_FACE_AMT := FN_ROUND(T_BF_SG_ITEM.FACE_AMT * (1 - T_EVENT_INFO.SELL_RT));
        T_AF_BOOK_AMT := FN_ROUND(T_BF_SG_ITEM.AF_BOOK_AMT * (1 - T_EVENT_INFO.SELL_RT));
        T_BF_SG_ITEM.FACE_AMT := FN_ROUND(T_BF_SG_ITEM.FACE_AMT * (1 - T_EVENT_INFO.SELL_RT));
        T_BF_SG_ITEM.AF_BOOK_AMT := FN_ROUND(T_BF_SG_ITEM.AF_BOOK_AMT * (1 - T_EVENT_INFO.SELL_RT));
        T_BF_SG_ITEM.AF_BOOK_AMT_EIR := FN_ROUND(T_BF_SG_ITEM.AF_BOOK_AMT_EIR * (1 - T_EVENT_INFO.SELL_RT));
      END IF;

      -- 1)액면금액
      T_SG_LIST(I).FACE_AMT := FN_ROUND(T_BF_SG_ITEM.FACE_AMT);
      
      -- 2)상각일수(현상각스케쥴의 기준일자 - 전상각스케쥴의 기준일자)
      T_SG_LIST(I).DAYS := FN_CALC_DAYS(T_BF_SG_ITEM.BASE_DATE, T_SG_LIST(I).BASE_DATE);
      
      ---------- 유효이자 계산용 ----------
      -- 기초장부금액(전상각스케쥴.기말장부금액)
      T_SG_LIST(I).BF_BOOK_AMT_EIR := T_BF_SG_ITEM.AF_BOOK_AMT_EIR;
      
      -- 유효이자(기초장부금액(EIR) * POWER(1 + EIR, 상각일수/365) -1))
      T_SG_LIST(I).EIR_INT_AMT := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT_EIR * (POWER(1+T_EVENT_RESULT.EIR, T_SG_LIST(I).DAYS/365) - 1));

      -- 실이자금액(이자지급일 OR 만기일에 실제 발생한 액면이자)
      IF I_EIR_C.BOND_TYPE = '1' THEN -- 이표채
        IF T_SG_LIST(I).SANGGAK_TYPE = '3' OR T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, FN_CALC_DAYS(T_REAL_INT_DATE, T_SG_LIST(I).BASE_DATE), T_SG_LIST(I).FACE_AMT, T_EVENT_RESULT.IR));
          T_REAL_INT_DATE := T_SG_LIST(I).BASE_DATE;
        END IF;
      ELSIF I_EIR_C.BOND_TYPE = '2' THEN -- 할인채
        T_SG_LIST(I).REAL_INT_AMT := 0;
      ELSIF I_EIR_C.BOND_TYPE = '3' THEN -- 단리채
        IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, FN_CALC_DAYS(T_REAL_INT_DATE, T_SG_LIST(I).BASE_DATE), T_SG_LIST(I).FACE_AMT, T_EVENT_RESULT.IR));
        END IF;
      ELSIF I_EIR_C.BOND_TYPE = '4' THEN -- 복리채
        IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
          T_SG_LIST(I).REAL_INT_AMT := FN_ROUND(FN_GET_CAL_CPND_INT(I_EIR_C, T_BF_SG_ITEM.BASE_DATE, T_SG_LIST(I).BASE_DATE));
        END IF;
      END IF;
      
      -- 상각금액(유효이자 - 실이자금액)
      T_SG_LIST(I).SANGGAK_AMT_EIR := FN_ROUND(T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).REAL_INT_AMT);
      
      -- 기말장부금액(기초장부금액(EIR) + 상각액(EIR))
      T_SG_LIST(I).AF_BOOK_AMT_EIR := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT_EIR + T_SG_LIST(I).SANGGAK_AMT_EIR);
      
      ----------상각액 상각표----------
      -- 3)기초장부금액(전상각스케쥴.기말장부금액)
      T_SG_LIST(I).BF_BOOK_AMT := T_BF_SG_ITEM.AF_BOOK_AMT;
      
      -- 4)액면이자(실발생이자 기준이 아닌 계산이자)
      IF I_EIR_C.BOND_TYPE <> '4' THEN
        T_SG_LIST(I).FACE_INT_AMT := FN_ROUND(FN_GET_CAL_INT(I_EIR_C.BOND_TYPE, T_SG_LIST(I).DAYS, T_SG_LIST(I).FACE_AMT, T_EVENT_RESULT.IR));
      ELSE
        -- 액면이자 * 상각일수 / 총일수
        T_SG_LIST(I).FACE_INT_AMT := FN_ROUND(FN_GET_CAL_CPND_INT(I_EIR_C, I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE) * T_SG_LIST(I).DAYS / FN_CALC_DAYS(I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE));
      END IF;
      
      -- 5)상각액(유효이자 - 액면이자)
      T_SG_LIST(I).SANGGAK_AMT := FN_ROUND(T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).FACE_INT_AMT);
      
      -- 6)기말장부금액(기초장부금액 + 상각액)
      T_SG_LIST(I).AF_BOOK_AMT := FN_ROUND(T_SG_LIST(I).BF_BOOK_AMT + T_SG_LIST(I).SANGGAK_AMT);
      
      -- 7)미상각잔액(액면금액 - 기말장부금액)
      T_SG_LIST(I).MI_SANGGAK_AMT := FN_ROUND(T_SG_LIST(I).FACE_AMT - T_SG_LIST(I).AF_BOOK_AMT);
      
      
      -- 만기일에 미상각잔액이 1이상이면 단수차에 의한 것이 아니라, EIR에 문제가 있는 것이므로 오류처리
--      IF T_SG_LIST(I).SANGGAK_TYPE = '4' THEN
--        IF T_SG_LIST(I).MI_SANGGAK_AMT > 1 THEN
--          PCZ_RAISE(-20999, '미상각잔액이 1이상 차이(미상각잔액:'||T_SG_LIST(I).MI_SANGGAK_AMT||')');
--        END IF;
--        
--        -- 만기일의 유효이자에 남은 미상각잔액 보정처리
--        IF T_SG_LIST(I).MI_SANGGAK_AMT <> 0 THEN
--          T_SG_LIST(I).EIR_INT_AMT := T_SG_LIST(I).EIR_INT_AMT + T_SG_LIST(I).MI_SANGGAK_AMT;
--          
--          T_SG_LIST(I).SANGGAK_AMT := T_SG_LIST(I).EIR_INT_AMT - T_SG_LIST(I).FACE_INT_AMT;
--          T_SG_LIST(I).AF_BOOK_AMT := T_SG_LIST(I).BF_BOOK_AMT + T_SG_LIST(I).SANGGAK_AMT;
--          T_SG_LIST(I).MI_SANGGAK_AMT := T_SG_LIST(I).FACE_AMT - T_SG_LIST(I).AF_BOOK_AMT;
--        END IF;
--      END IF;
      
      -- 계산을 위한 전상각스케쥴 저장
      T_BF_SG_ITEM := T_SG_LIST(I);
    END LOOP;

    FOR I IN 1..T_SG_LIST.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(PKG_EIR_TKP_S.FN_GET_SANGGAK_FLOW_STR(T_SG_LIST(I)));
    END LOOP;
    
    
    DBMS_OUTPUT.PUT_LINE('--- INSERT(Event 결과정보) ---');
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
  

  -- FROM ~ TO 일수계산
  FUNCTION FN_CALC_DAYS(I_FROM_DATE CHAR, I_TO_DATE CHAR)
    RETURN NUMBER AS
    T_DAYS NUMBER; -- 계산된 일수
  BEGIN
    T_DAYS := TO_DATE(I_TO_DATE,'YYYYMMDD') - TO_DATE(I_FROM_DATE,'YYYYMMDD');
    RETURN T_DAYS;
  END;


  -- 이자발생횟수 계산
  FUNCTION FN_GET_INT_CNT(I_EIR_C EIR_CALC_INFO)
    RETURN NUMBER AS
    T_INT_CNT NUMBER; -- 이자발생횟수
    T_EVENT_DATE DATE := TO_DATE(I_EIR_C.EVENT_DATE, 'YYYYMMDD'); -- EVENT 발생일 (기준일)
    T_ISSUE_DATE DATE := TO_DATE(I_EIR_C.ISSUE_DATE, 'YYYYMMDD'); -- 발행일
  BEGIN
    T_INT_CNT := TRUNC(MONTHS_BETWEEN(T_EVENT_DATE, T_ISSUE_DATE) / I_EIR_C.INT_CYCLE);
    RETURN T_INT_CNT;
  END;


  -- 직전이자지급일 계산
  FUNCTION FN_GET_BF_INT_DATE(I_EIR_C EIR_CALC_INFO)
    RETURN CHAR AS
    T_INT_CNT NUMBER; -- 이자발생횟수
    T_BF_INT_DATE CHAR(8); -- 직전이자지급일
    T_EVENT_DATE DATE := TO_DATE(I_EIR_C.EVENT_DATE, 'YYYYMMDD'); -- EVENT 발생일 (기준일)
    T_ISSUE_DATE DATE := TO_DATE(I_EIR_C.ISSUE_DATE, 'YYYYMMDD'); -- 발행일
  BEGIN
    T_INT_CNT := TRUNC(MONTHS_BETWEEN(T_EVENT_DATE, T_ISSUE_DATE) / I_EIR_C.INT_CYCLE);
    T_BF_INT_DATE := TO_CHAR(ADD_MONTHS(T_ISSUE_DATE, T_INT_CNT*I_EIR_C.INT_CYCLE), 'YYYYMMDD');
    RETURN T_BF_INT_DATE;
  END;
  
  
  -- 직후이자지급일 계산
  FUNCTION FN_GET_AF_INT_DATE(I_EIR_C EIR_CALC_INFO)
    RETURN CHAR AS
    T_INT_CNT NUMBER; -- 이자발생횟수
    T_AF_INT_DATE CHAR(8); -- 직후이자지급일
    T_EVENT_DATE DATE := TO_DATE(I_EIR_C.EVENT_DATE, 'YYYYMMDD'); -- EVENT 발생일 (기준일)
    T_ISSUE_DATE DATE := TO_DATE(I_EIR_C.ISSUE_DATE, 'YYYYMMDD'); -- 발행일
  BEGIN
    T_INT_CNT := TRUNC(MONTHS_BETWEEN(T_EVENT_DATE, T_ISSUE_DATE) / I_EIR_C.INT_CYCLE);
    T_AF_INT_DATE := TO_CHAR(ADD_MONTHS(T_ISSUE_DATE, (T_INT_CNT+1)*I_EIR_C.INT_CYCLE), 'YYYYMMDD');
    RETURN T_AF_INT_DATE;
  END;


  -- 금액 절사
  FUNCTION FN_ROUND(I_NUM NUMBER)
    RETURN NUMBER AS
    T_AMT NUMBER; -- 금액(절사 소수2자리)
  BEGIN
    T_AMT := TRUNC(I_NUM);
    RETURN T_AMT;
  END;
  
  FUNCTION FN_ROUND(I_NUM NUMBER, I_DIGITS NUMBER)
    RETURN NUMBER AS
    T_AMT NUMBER; -- 금액(절사 소수2자리)
  BEGIN
    T_AMT := TRUNC(I_NUM, I_DIGITS);
    RETURN T_AMT;
  END;
  
  
  -- 기존 SGF_LIST 동일 EVENT일의 상각스케쥴 SEQ GET
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
    V_STR :=   '채권코드['||I_EV_RET.BOND_CODE||']'      
             ||'매수일자['||I_EV_RET.BUY_DATE||']'       
             ||'이벤트일['||I_EV_RET.EVENT_DATE||']'     
             ||'순번['||I_EV_RET.EVENT_SEQ||']'     
             ||'이벤트종류['||I_EV_RET.EVENT_TYPE||']'     
             ||'표면이자율['||LPAD(I_EV_RET.IR, 10)||']'
             ||'유효이자율['||LPAD(I_EV_RET.EIR,15)||']'
             ||'매도율['||LPAD(I_EV_RET.SELL_RT, 5)||']'
             ||'액면금액['||LPAD(I_EV_RET.FACE_AMT,10)||']'
             ||'장부금액['||LPAD(I_EV_RET.BOOK_AMT,10)||']';
    RETURN V_STR;
  END FN_GET_EVENT_RESULT_NESTED_STR;
  FUNCTION FN_GET_CASH_FLOW_STR(I_CF CF_TYPE_S) RETURN VARCHAR2 IS
    V_STR VARCHAR2(1000);
  BEGIN
    V_STR :=   '기준일['||I_CF.BASE_DATE||']'
             ||'액면['||LPAD(I_CF.FACE_AMT,10)||']'
             ||'총일수['||LPAD(I_CF.TOT_DAYS,10)||']'
             ||'이자일수['||LPAD(I_CF.INT_DAYS,10)||']'
             ||'이자금액['||LPAD(I_CF.INT_AMT,10)||']'
             ||'원금['||LPAD(I_CF.PRC_AMT,10)||']'
             ||'현재가치['||LPAD(I_CF.CUR_VALUE,10)||']';
    RETURN V_STR;
  END FN_GET_CASH_FLOW_STR;
  FUNCTION FN_GET_SANGGAK_FLOW_STR(I_SGF SGF_TYPE_S) RETURN VARCHAR2 IS
    V_STR VARCHAR2(1000);
  BEGIN
    V_STR :=  '기준일['||I_SGF.BASE_DATE||']'       
            ||'SEQ['||I_SGF.SEQ||']'
            ||'TYPE['||I_SGF.SANGGAK_TYPE||']'
            ||'일수['||LPAD(I_SGF.DAYS,4)||']'            
            ||'액면['||LPAD(I_SGF.FACE_AMT,10)||']'        
            ||'기초장부['||LPAD(I_SGF.BF_BOOK_AMT,10)||']'     
            ||'유효이자['||LPAD(I_SGF.EIR_INT_AMT,10)||']'     
            ||'액면이자['||LPAD(I_SGF.FACE_INT_AMT,10)||']'    
            ||'상각액['||LPAD(I_SGF.SANGGAK_AMT,10)||']'     
            ||'기말장부['||LPAD(I_SGF.AF_BOOK_AMT,10)||']'     
            ||'미상각액['||LPAD(I_SGF.MI_SANGGAK_AMT,10)||']'  
            ||'기초장부_E['||LPAD(I_SGF.BF_BOOK_AMT_EIR,10)||']' 
            ||'실이자['||LPAD(I_SGF.REAL_INT_AMT,10)||']'    
            ||'상각액_E['||LPAD(I_SGF.SANGGAK_AMT_EIR,10)||']' 
            ||'기말장부_E['||LPAD(I_SGF.AF_BOOK_AMT_EIR,10)||']';
     RETURN V_STR;       
  END FN_GET_SANGGAK_FLOW_STR;
  

END PKG_EIR_TKP_S;