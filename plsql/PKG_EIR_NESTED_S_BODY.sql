CREATE OR REPLACE PACKAGE BODY PKG_EIR_NESTED_S AS
  
  -- 최초 매수 EVENT 반영 (IN : Event Info, OUT : EVENT_RESULT Class)
  PROCEDURE PR_APPLY_NEW_BUY_EVENT(I_EV_INFO IN EVENT_INFO_TYPE, O_EV_RET IN OUT EVENT_RESULT_NESTED_S%ROWTYPE) IS
    V_EIR_C        EIR_CALC_INFO; -- Event Calculation Info
    V_EIR          NUMBER := 0; -- 유효이자율
    V_LOG_STR      VARCHAR2(300); -- <LOG>
  BEGIN
    -- <NOT_DEF> Validation Check, 나중에 하자
    -- 매수기준 Validation (NULL체크, 0 <= IR < 1, FACE_AMT > 0, BOOK_AMT > 0)
    
    -- O_EV_RET의 필드값을 I_EV_INFO로 SET
    O_EV_RET.BOND_CODE   := I_EV_INFO.BOND_CODE  ; 
    O_EV_RET.BUY_DATE    := I_EV_INFO.BUY_DATE   ; 
    O_EV_RET.EVENT_DATE  := I_EV_INFO.EVENT_DATE ;
    O_EV_RET.EVENT_SEQ   := 1;   -- <EVENT_SEQ> EVENT 순번은 1
    O_EV_RET.EVENT_TYPE  := I_EV_INFO.EVENT_TYPE ; 
    O_EV_RET.IR          := I_EV_INFO.IR         ; 
    O_EV_RET.EIR         := I_EV_INFO.EIR        ; 
    O_EV_RET.SELL_RT     := I_EV_INFO.SELL_RT    ; 
    O_EV_RET.FACE_AMT    := I_EV_INFO.FACE_AMT   ; 
    O_EV_RET.BOOK_AMT    := I_EV_INFO.BOOK_AMT   ; 
    
    -- 해당 Event로 EIR_CALC_INFO GET
    V_EIR_C   := FN_GET_EIR_CALC_INFO(I_EV_INFO);
    
    -- EIR Simulation (V_EIR OUT)
    O_EV_RET.CF_LIST := FN_SIMULATE_EIR(V_EIR_C, V_EIR);
    -- EIR SET
    O_EV_RET.EIR := V_EIR;
    V_EIR_C.EIR  := V_EIR;

    -- Create 상각스케쥴 
    O_EV_RET.SGF_LIST := FN_CREATE_SANGGAK_FLOWS(V_EIR_C, O_EV_RET.CF_LIST);
    
    -- DB INSERT (BULK INSERT)
    -- EVENT_RESULT_NESTED_S 생성
    INSERT INTO EVENT_RESULT_NESTED_S VALUES O_EV_RET;

  END PR_APPLY_NEW_BUY_EVENT;
  
  -- 추가 Event 반영 Procedure (IN : Event Info, OUT : EVENT_RESULT Class)
  PROCEDURE PR_APPLY_ADDTIONAL_EVENT(I_EV_INFO IN EVENT_INFO_TYPE, O_EV_RET IN OUT EVENT_RESULT_NESTED_S%ROWTYPE) IS
    V_CF            CF_TYPE_S;
    V_SGF           SGF_TYPE_S;
    V_BF_SGF        SGF_TYPE_S;
    V_EIR_C         EIR_CALC_INFO; -- Event Calculation Info
    V_LAST_FACE_AMT NUMBER := 0; -- 최종 EVENT의 액면금액
    V_LAST_BOOK_AMT NUMBER := 0; -- 최종 EVENT의 장부금액
    V_IS_FOUND      BOOLEAN := FALSE;
    V_NEW_EIR       NUMBER := 0; -- 금리변동시 새로 적용된 EIR
    V_IS_CALC       BOOLEAN := FALSE; -- 상각스케쥴 계산 FLAG
    V_EVENT_IDX     NUMBER := 0; -- EVENT 발생일의 SGF_LIST에서의 INDEX
    V_LOG_STR       VARCHAR2(300); -- <LOG>
    V_MY_SGF_SEQ    NUMBER := 0; -- <EVENT_SEQ> 매도,손상에 의해 추가된 SGF의 SEQ, 금리변동시는 자신 SGF SEQ
    V_IS_CALL_DONE  BOOLEAN := FALSE; -- <CALL_IR_CHANGE> 금리변동일때 CALL을 행사했는지 여부 (금리변동시 액면금액 <> 최종액면금액과 다를때 TRUE)
  BEGIN
    -- 해당잔고의 최종 EVENT 결과정보 LOAD
    O_EV_RET := FN_GET_LAST_EVELT_RESULT(I_EV_INFO);
    
    -- 최종 EVENT의 액면금액, 장부금액 보관
    V_LAST_FACE_AMT := O_EV_RET.FACE_AMT;
    V_LAST_BOOK_AMT := O_EV_RET.BOOK_AMT;
    
    -- 해당 Event로 EIR_CALC_INFO GET
    V_EIR_C   := FN_GET_EIR_CALC_INFO(I_EV_INFO);
    
    -- Event 유효성 검사 (1.매수, 5.회복)은 처리불가
    IF I_EV_INFO.EVENT_TYPE IN ('1','5') THEN -- 1.매수 (추가 Event 불가)
      RAISE_APPLICATION_ERROR(-20011, '매수,손상 Event는 추가 Event로 처리불가');
    END IF;
    IF I_EV_INFO.EVENT_DATE < O_EV_RET.EVENT_DATE THEN
      RAISE_APPLICATION_ERROR(-20011, 'Event 일자는 최종 Event 일자보다 크거나 같아야 함.');
    END IF;
    IF I_EV_INFO.EVENT_DATE >= V_EIR_C.EXPIRE_DATE THEN
      RAISE_APPLICATION_ERROR(-20011, 'Event 일자는 만기일보다 작아야 함.');
    END IF;
    -- IF 2.매도 THEN 0 < 매도 <= 1 (%기준이 아님)
    IF I_EV_INFO.EVENT_TYPE = '2' THEN -- 2.매도
      IF I_EV_INFO.SELL_RT <= 0 OR I_EV_INFO.SELL_RT > 1 THEN
        RAISE_APPLICATION_ERROR(-20011, '매도 Event의 0 < 매도비율['||I_EV_INFO.SELL_RT||'] <= 1 이어야 함.');
      END IF;
    END IF;
    -- IF 3.IR변경 THEN 변경IR > 0
    IF I_EV_INFO.EVENT_TYPE = '3' THEN -- 3.IR변경
      IF I_EV_INFO.IR <= 0 THEN
        RAISE_APPLICATION_ERROR(-20011, '금리변경 Event의 이자율['||I_EV_INFO.IR||'] > 0 이어야 함.');
      END IF;
      -- 최종정보의 IR과 동일하면 안됨
      IF I_EV_INFO.IR = O_EV_RET.IR THEN
        RAISE_APPLICATION_ERROR(-20011, '금리변경 Event의 이자율['||I_EV_INFO.IR||']이 최종 Event와 동일합니다.처리불가');
      END IF;
    END IF;
    
    -- O_EV_RET의 EV_INFO, CF_LIST, SFG_LIST의 EVENT일자, EVENT_TYPE을 I_EV_INFO의 값으로 변경 (새로운 KEY 값 적용)
    O_EV_RET.EVENT_DATE := I_EV_INFO.EVENT_DATE;
    O_EV_RET.EVENT_TYPE := I_EV_INFO.EVENT_TYPE;
    -- <EVENT_SEQ> O_EV_RET.EVENT_SEQ SET (동일 EVENT일의 2개이상 EVENT 발생 고려)
    O_EV_RET.EVENT_SEQ  := FN_GET_EVENT_SEQ(I_EV_INFO);
    
    -- 매도율(매도시만 SET), IR(이자율 변경시만 SET)
    IF I_EV_INFO.EVENT_TYPE = '2' THEN -- 2.매도
      O_EV_RET.SELL_RT    := I_EV_INFO.SELL_RT;
      -- 계산시 사용할 IR은 최종정보의 IR
      V_EIR_C.IR  := O_EV_RET.IR; 
    ELSE
      O_EV_RET.SELL_RT    := 0; -- 그외는 0
    END IF;
    IF I_EV_INFO.EVENT_TYPE = '3' THEN -- 3.이자율 (이자율변경시는 변경된 이자율, 그외는 원이자율)
      O_EV_RET.IR := I_EV_INFO.IR;
      -- 계산시 사용할 IR은 변경된 IR
      V_EIR_C.IR  := I_EV_INFO.IR;
    END IF;
    
    -- EVENT 유형에 따른 현재 EVENT의 액면금액, 장부금액 등을 설정
    -- IF 2.매도 THEN 액면금액= 최종액면금액 *(1- 매도율), 장부금액 = 최종장부금액 *(1- 매도율), 매도에 따라 액면금액,장부금액 감소
    IF I_EV_INFO.EVENT_TYPE = '2' THEN
      O_EV_RET.FACE_AMT := FN_ROUND(V_LAST_FACE_AMT * (1 - I_EV_INFO.SELL_RT));
      O_EV_RET.BOOK_AMT := FN_ROUND(V_LAST_BOOK_AMT * (1 - I_EV_INFO.SELL_RT));
    ELSIF I_EV_INFO.EVENT_TYPE = '3' THEN -- 금리변동
      -- 이자수령일에 금리가 변동되므로 해당 기준일의 기존 상각스케쥴에 있는 기말장부금액을 장부금액으로 설정하여 Cash Flow와 EIR을 다시 계산해야함.
      FOR IDX IN 1..O_EV_RET.SGF_LIST.COUNT LOOP
        V_SGF := O_EV_RET.SGF_LIST(IDX);
        --IF  기준일 = Event발생일 AND Type = 3.이자지급 THEN 최종장부금액 = 상각Flow.기말장부금액
        IF V_SGF.BASE_DATE = I_EV_INFO.EVENT_DATE AND V_SGF.SANGGAK_TYPE = '3' THEN
          V_LAST_BOOK_AMT := V_SGF.AF_BOOK_AMT;
          V_MY_SGF_SEQ    := V_SGF.SEQ;  -- <EVENT_SEQ> 동일 기준일에서의 자신의 SEQ SET
          V_IS_FOUND := TRUE;
          EXIT;
        END IF;
      END LOOP;
      -- 이자지급일의 상각스케쥴에 기말장부금액이 없으면 기존 상각스케쥴에 문제가 있는 것임
      IF NOT V_IS_FOUND THEN
        RAISE_APPLICATION_ERROR(-20011, '해당일자에 기존 상각스케쥴의 기말장부금액을 찾을 수 없음.(처리불가)');
      END IF;
      
      -- 2014.03.02 <CALL_IR_CHANGE> CALL행사후 금리변동 고려, 단순한 금리변동이 아닌 CALL 행사후 금리변동시 I_EV_INFO.FACE_AMT가 V_LAST_FACE_AMT와 다르면 
      -- V_LAST_BOOK_AMT = V_LAST_BOOK_AMT * (I_EV_INFO.FACE_AMT/V_LAST_FACE_AMT)로 안분처리한다.
      IF I_EV_INFO.FACE_AMT > 0 THEN
        IF I_EV_INFO.FACE_AMT > V_LAST_FACE_AMT THEN
          RAISE_APPLICATION_ERROR(-20011, '변경후 액면금액['||I_EV_INFO.FACE_AMT||']가 최종액면금액['||V_LAST_FACE_AMT||']보다 큽니다.(처리불가)');
        END IF;
        -- CALL행사로 인해 액면금액이 감소하였으면
        IF I_EV_INFO.FACE_AMT <> V_LAST_FACE_AMT THEN
          V_LAST_BOOK_AMT := FN_ROUND(V_LAST_BOOK_AMT * I_EV_INFO.FACE_AMT / V_LAST_FACE_AMT);
          V_LAST_FACE_AMT := I_EV_INFO.FACE_AMT;
          -- CALL행사 FLAG SET
          V_IS_CALL_DONE := TRUE;
        END IF;
      END IF;
      
      -- 현재 EVENT의 IR, 액면금액, 장부금액 설정
      O_EV_RET.IR       := I_EV_INFO.IR; -- 금리 SET
      O_EV_RET.FACE_AMT := V_LAST_FACE_AMT;
      O_EV_RET.BOOK_AMT := V_LAST_BOOK_AMT;
      
      -- V_EIR_C의 IR, 액면금액, 장부금액 다시 설정(새로운 EIR과 Cash Flow를 만들어야함)
      V_EIR_C.IR       := I_EV_INFO.IR;
      V_EIR_C.FACE_AMT := V_LAST_FACE_AMT;
      V_EIR_C.BOOK_AMT := V_LAST_BOOK_AMT;
      
      -- EIR 다시 Simulation하고 새로 생성된 Cash Flow를 O_EV_RET.CF_LIST에 할당함.
      O_EV_RET.CF_LIST := FN_SIMULATE_EIR(V_EIR_C, V_NEW_EIR);
      -- 변경된 EIR 설정
      O_EV_RET.EIR := V_NEW_EIR;
      V_EIR_C.EIR  := V_NEW_EIR;
    END IF; -- END OF IF I_EV_INFO.EVENT_TYPE = '2' THEN
      
    -- 2.매도, 4.손상시는 새로운 EVENT에 대한 상각 Flow를 생성하여 Collection에 Add한다.
    -- 3.금리변경시는 이미 기 상각Flow가 있으므로 추가로 Add하지 않는다. (기존 이자지급일의 상각Flow)
    IF I_EV_INFO.EVENT_TYPE IN ('2','4') THEN -- 2.매도
      -- EVENT일의 상각 Flow를 추가
      PR_INIT_SGF(V_SGF); -- 초기화
      V_SGF.BASE_DATE    := I_EV_INFO.EVENT_DATE; -- 기준일자 = 취득일자
      V_SGF.SEQ          := FN_GET_SGF_SEQ(V_SGF.BASE_DATE, O_EV_RET.SGF_LIST); -- <EVENT_SEQ> 동일 EVENT일의 상각 SEQ SET
      V_MY_SGF_SEQ       := V_SGF.SEQ;  -- <EVENT_SEQ> 동일 기준일에서의 자신의 SEQ SET
      IF I_EV_INFO.EVENT_TYPE = '2' THEN
        V_SGF.SANGGAK_TYPE := '2'; -- 2.매도
      ELSE
        V_SGF.SANGGAK_TYPE := '7'; -- 7.손상
      END IF;
      V_SGF.FACE_AMT     := V_LAST_FACE_AMT; -- 액면금액 = 최종액면금액
      
      -- Set to List (마지막 다음에 SET) - 일자기준 Sort는 아래에서 함.
      -- <주의> TYPE의 TABLE일 경우에는 바로 할당하면 실행시 ora 6533 subscript beyond count 에러발생, EXTEND후에 SET 필요
      O_EV_RET.SGF_LIST.EXTEND;
      O_EV_RET.SGF_LIST(O_EV_RET.SGF_LIST.COUNT) := V_SGF;
    END IF;
    
    -- Sort 상각 Flows
    PR_SORT_SANGGAK_FLOWS(O_EV_RET.SGF_LIST);
    
    /* 기준일 및 기준일 이후 상각스케쥴 처리 규칙 (기준일 이전의 상각스케쥴을 변경하지 않는다.)
     * IF 기준일 상각스케쥴 AND (매도 OR 손상) THEN
     *    상각스케쥴 계산 FLAG = TRUE
     * ELSE IF 매도 AND 기준일 다음 첫번째 상각스케쥴 THEN
     *    액면금액 = 액면금액*(1- 매도율), 기초장부금액, 기초장부금액(EIR) = 매도일상각스케쥴.기말장부금액*(1-매도율)로 설정.
     * ELSE 
     * IF 기준일의 상각스케쥴 THEN
     *     IF 매도 OR 손상 THEN 
     *        상각스케쥴 계산 FLAG = TRUE
     *     ELSE
     *        상각스케줄 계산 FLAG = false (재계산 하지 않음)
     *     END IF
     * ELSE IF 기준일 다음 첫번째 상각스케쥴 THEN
     *   IF 매도 THEN
     *      액면금액 = 액면금액*(1- 매도율), 기초장부금액, 기초장부금액(EIR) = 매도일상각스케쥴.기말장부금액*(1-매도율)로 설정.
     *   END IF
     *   상각스케쥴 계산 FLAG = TRUE
     * ELSE //이후 상각스케쥴
     *   상각스케쥴 계산 FLAG = TRUE
     * END IF
    */
    V_IS_FOUND := FALSE;
    FOR IDX IN 1..O_EV_RET.SGF_LIST.COUNT LOOP
      V_IS_CALC := FALSE;
      V_SGF := O_EV_RET.SGF_LIST(IDX);
      -- <EVNET_SEQ> IF IDX = 1 THEN 이전 SGF 설정후 SKIP
      IF IDX = 1 THEN
        V_BF_SGF := V_SGF;
        V_IS_FOUND := TRUE;
        GOTO SKIP_LOOP;
      ELSE
	    -- 해당 EVENT일의 이전 상각Flow이면 V_BF_SGF에 SET (해당 EVENT일의 직전 상각Flow를 V_BF_SGF에 설정하도록 계속 LOOP를 돈다.
	    IF V_SGF.BASE_DATE < I_EV_INFO.EVENT_DATE THEN
		  V_BF_SGF := V_SGF;
		  V_IS_FOUND := TRUE;
		  GOTO SKIP_LOOP;
	    -- <EVENT_SEQ> IF SGF.기준일 = EVENT일 AND SGF.SEQ < V_MY_SGF_SEQ THEN (자신의 SEQ보다 작으면 SET)
	    ELSIF V_SGF.BASE_DATE = I_EV_INFO.EVENT_DATE THEN 
		  IF V_SGF.SEQ < V_MY_SGF_SEQ THEN
		    V_BF_SGF := V_SGF;
		    V_IS_FOUND := TRUE;
		    GOTO SKIP_LOOP;
		  END IF;
	    END IF;
      END IF;
      
      IF NOT V_IS_FOUND THEN --  직전상각Flow가 없다는 것은 기존 상각스케쥴에 문제가 있는 것임.
        RAISE_APPLICATION_ERROR(-20011, '이벤트 발생일보다 기준일이 작은 상각스케쥴이 없음. 상각스케쥴이 이상함.');
      END IF;
      
      --기준일의 상각스케쥴 
      IF V_SGF.BASE_DATE = I_EV_INFO.EVENT_DATE THEN
        -- <EVENT_SEQ> 동일 기준일에 여러 EVENT 발생가능, 일자만 비교하지 말고, 동일한 EVENT인지를 비교해야함.
        -- V_EVENT_IDX 설정
        V_EVENT_IDX := IDX;
        -- 2.매도 OR 4.손상시 새로추가된 상각 Flow의 기초장부금액을 설정, 이자율변동은 기존 상각 Flow그대로 사용
        IF I_EV_INFO.EVENT_TYPE IN ('2','4') THEN
          -- 상각스케쥴 재계산 (추가된 상각스케쥴의 값을 재계산)
          V_IS_CALC := TRUE;
          --기초장부금액 = 전상각스케쥴.기말장부금액* (현상각스케쥴.액면금액/전상각스케쥴.액면금액) 안분
          --<WHY> 안분이유는 매도후 다음 상각스케쥴 사이에 다시매도,손상등의 EVENT 발생시에
          --현 상각스케쥴과 전상각스케쥴 사이에 액면금액의 변화가 발생하므로 액면금액의 비로 안분해야함.
          V_SGF.BF_BOOK_AMT     := FN_ROUND(V_BF_SGF.AF_BOOK_AMT * V_SGF.FACE_AMT / V_BF_SGF.FACE_AMT);
          --기초장부금액(EIR) = 전상각스케쥴.기말장부금액(EIR) * (현상각스케쥴.액면금액/전상각스케쥴.액면금액) 안분
          V_SGF.BF_BOOK_AMT_EIR := FN_ROUND(V_BF_SGF.AF_BOOK_AMT_EIR * V_SGF.FACE_AMT / V_BF_SGF.FACE_AMT);
        END IF;
      -- 기준일 다음 첫번째 상각스케쥴
      ELSIF IDX = V_EVENT_IDX + 1 THEN
        -- 상각스케쥴 재계산
        V_IS_CALC := TRUE;
        -- 매도시는 매도율로 안분하여 액면금액, 기초장부금액 감소처리
        IF I_EV_INFO.EVENT_TYPE = '2' THEN
          --액면금액 = 액면금액*(1- 매도율(%)), 
          V_SGF.FACE_AMT        := FN_ROUND(V_BF_SGF.FACE_AMT * (1 - I_EV_INFO.SELL_RT));
          --기초장부금액, 기초장부금액(EIR) = 매도일상각스케쥴.기말장부금액*(1-매도율)로 설정.
          V_SGF.BF_BOOK_AMT     := FN_ROUND(V_BF_SGF.AF_BOOK_AMT * (1 - I_EV_INFO.SELL_RT));
          V_SGF.BF_BOOK_AMT_EIR := FN_ROUND(V_BF_SGF.AF_BOOK_AMT_EIR * (1 - I_EV_INFO.SELL_RT));
        ELSE
          -- 그외는 이전상각스케쥴의 값으로 설정 (액면금액, 기초장부금액 = 이전스케쥴.기말장부금액)
          V_SGF.FACE_AMT        := V_BF_SGF.FACE_AMT;
          V_SGF.BF_BOOK_AMT     := V_BF_SGF.AF_BOOK_AMT;
          V_SGF.BF_BOOK_AMT_EIR := V_BF_SGF.AF_BOOK_AMT_EIR;
          
          -- <CALL_IR_CHANGE> CALL행사후 금리변동시에는 V_SGF.기초장부금액을 안분 (기초장부금액*변경후액면금액/변경전액면금액)
          IF V_IS_CALL_DONE THEN
            -- 기초장부금액 = 원기초장부금액 * 변경후액면금액/변경전액면금액 안분
            V_SGF.BF_BOOK_AMT := FN_ROUND(V_SGF.BF_BOOK_AMT * O_EV_RET.FACE_AMT/V_SGF.FACE_AMT);  
            -- 기초장부금액(EIR) = 원기초장부금액(EIR) * 변경후액면금액/변경전액면금액 안분
            V_SGF.BF_BOOK_AMT_EIR := FN_ROUND(V_SGF.BF_BOOK_AMT_EIR * O_EV_RET.FACE_AMT/V_SGF.FACE_AMT);
            -- 액면금액 = 감소한 액면금액 <주의> 액면금액을 맨 마지막에 변경함.
            V_SGF.FACE_AMT    := O_EV_RET.FACE_AMT;
          END IF;
        END IF;
      ELSE -- 이후 상각스케쥴
        -- 상각스케쥴 재계산
        V_IS_CALC := TRUE;
        -- 그외는 이전상각스케쥴의 값으로 설정 (액면금액, 기초장부금액 = 이전스케쥴.기말장부금액)
        V_SGF.FACE_AMT        := V_BF_SGF.FACE_AMT;
        V_SGF.BF_BOOK_AMT     := V_BF_SGF.AF_BOOK_AMT;
        V_SGF.BF_BOOK_AMT_EIR := V_BF_SGF.AF_BOOK_AMT_EIR;
      END IF;
      
      -- 상각스케쥴 재계산시만 다시 계산 (SKIP)
      IF NOT V_IS_CALC THEN
        -- Set V_SGF TO V_BF_SGF;
        V_BF_SGF := V_SGF;
        GOTO SKIP_LOOP;
      END IF;
      
      --상각일수 = 현상각스케쥴.일자 - 전상각스케쥴.일자
      V_SGF.DAYS := FN_CALC_DAYS(V_BF_SGF.BASE_DATE, V_SGF.BASE_DATE);
      -- 액면이자 (단리,복리로 나누어 계산), 실 이자 발생기준이 아닌 계산기준
      IF V_EIR_C.BOND_TYPE = '4' THEN -- 4.복리채
        --현상각스케쥴.기준일자까지의 복리이자 - 전상각스케쥴.기준일자까지의 복리이자 (상각스케쥴의 액면금액 기준)
        --액면금액 = 상각스케쥴.액면금액
        V_EIR_C.FACE_AMT   := V_SGF.FACE_AMT;
        V_SGF.FACE_INT_AMT := FN_CALC_INT_OF_COMPOUND(V_EIR_C, V_SGF.BASE_DATE) - FN_CALC_INT_OF_COMPOUND(V_EIR_C, V_BF_SGF.BASE_DATE);
      ELSIF V_EIR_C.BOND_TYPE = '2' THEN -- 2.할인채 (할인채는 액면이자 계산하지 않음)
        V_SGF.FACE_INT_AMT := 0;
      ELSE -- 단리채
        --단리 = 액면금액(상각스케쥴기준) * 이자율(Event정보기준) * 일수/365
        V_SGF.FACE_INT_AMT := FN_ROUND(V_SGF.FACE_AMT * O_EV_RET.IR * V_SGF.DAYS/365);
      END IF;
      
      --유효이자 = 기초장부금액(EIR) * (POWER(1+ EIR, 일수/365) -1)
      V_SGF.EIR_INT_AMT := FN_ROUND(V_SGF.BF_BOOK_AMT_EIR * (POWER(1 + O_EV_RET.EIR, V_SGF.DAYS/365) -1));
      --실발생이자 = CashFlow에서 해당기준일에 있는 이자금액(이자지급일 OR 만기일에 실제받는 이자)
      --<EVENT_SEQ> 동일 EVENT 일에 여러 EVENT 발생을 고려하여 실발생이자는 V_SGF.SANGGAK_TYPE = 3.이자수령 OR 4.만기 일 경우만 SET
      V_SGF.REAL_INT_AMT := 0;
      IF V_SGF.SANGGAK_TYPE IN ('3','4') THEN
        FOR JDX IN 1..O_EV_RET.CF_LIST.COUNT LOOP
          V_CF := O_EV_RET.CF_LIST(JDX);
          IF V_CF.BASE_DATE = V_SGF.BASE_DATE THEN
            -- <주의> EIR기준 실제발생이자계산시 CashFlows를 생성한 액면금액과 item의 액면금액이 다를 수 있으므로,
            -- 차감할 실발생이자는 CashFlow의 이자금액을 그대로 쓰지 않고, CashFlow를 생성한 액면금액과 item의 액면금액으로 안분한다.
            -- 실발생이자 = CashFlow.이자금액 * (item.액면금액/CashFlow.액면금액)
            V_SGF.REAL_INT_AMT := FN_ROUND(V_CF.INT_AMT * V_SGF.FACE_AMT/V_CF.FACE_AMT);
            EXIT;
          END IF;
        END LOOP;
      END IF;
      
      --상각액 = 유효이자 - 액면이자
      V_SGF.SANGGAK_AMT     := V_SGF.EIR_INT_AMT - V_SGF.FACE_INT_AMT;
      --상각액(EIR) = 유효이자 - 실발생이자
      V_SGF.SANGGAK_AMT_EIR := V_SGF.EIR_INT_AMT - V_SGF.REAL_INT_AMT;
      --기말장부금액 = 기초장부금액 + 상각액
      V_SGF.AF_BOOK_AMT     := V_SGF.BF_BOOK_AMT + V_SGF.SANGGAK_AMT;
      --기말장부금액(EIR) = 기초장부금액(EIR) + 상각액(EIR)
      V_SGF.AF_BOOK_AMT_EIR := V_SGF.BF_BOOK_AMT_EIR + V_SGF.SANGGAK_AMT_EIR;
      -- 미상각잔액 = 액면금액 - 기말장부금액
      V_SGF.MI_SANGGAK_AMT  := V_SGF.FACE_AMT - V_SGF.AF_BOOK_AMT;
      
      --유효이자,액면이자 계산시 소수 2자리 절사로 인해, 만기시에도 미상각잔액이 남는다. 
      --따라서,만기일에 미상각잔액이 남아 있으면 해당 잔액을 0으로 하면서 유효이자,장부금액을 보정한다. 미상각잔액은 Clear
      --<EVENT_SEQ> 마지막의 판단 기준은 IDX = V_SGF_LIST.COUNT로 설정함. (동일한 기준일에 2개이상의 SGF가 들어갈 수 있음)
      --IF V_SGF.BASE_DATE = I_EIR_C.EXPIRE_DATE AND V_SGF.MI_SANGGAK_AMT <> 0 THEN
      IF IDX = O_EV_RET.SGF_LIST.COUNT AND V_SGF.MI_SANGGAK_AMT <> 0 THEN
        --잘못 계산하여 미상각잔액이 1이상이면 문제가 있는것임. (단수차가 아님)
        -- <FOR_KOREA_BOND> 절사에 의한 미상각잔액 10이상
        --IF ABS(V_SGF.MI_SANGGAK_AMT) >= 1 THEN
        IF ABS(V_SGF.MI_SANGGAK_AMT) >= 10 THEN
          RAISE_APPLICATION_ERROR(-20011, '만기일의 미상각잔액['||V_SGF.MI_SANGGAK_AMT||'] >= 10, 단수차 보정불가, 원인확인요');
        END IF;
        --<LOG>
        V_LOG_STR := '[FN_CREATE_SANGGAK_FLOWS] 만기 미상각잔액['||V_SGF.MI_SANGGAK_AMT||'] <> 0, 유효이자['||V_SGF.EIR_INT_AMT||']에 보정처리';
        DBMS_OUTPUT.PUT_LINE(V_LOG_STR);
        
        --유효이자 보정 : 유효이자 += 미상각잔액
        V_SGF.EIR_INT_AMT := V_SGF.EIR_INT_AMT + V_SGF.MI_SANGGAK_AMT;
        -- 상각액, 기말장부금액 다시 계산
        --상각액 = 유효이자 - 액면이자
        V_SGF.SANGGAK_AMT     := V_SGF.EIR_INT_AMT - V_SGF.FACE_INT_AMT;
        --상각액(EIR) = 유효이자 - 실발생이자
        V_SGF.SANGGAK_AMT_EIR := V_SGF.EIR_INT_AMT - V_SGF.REAL_INT_AMT;
        --기말장부금액 = 기초장부금액 + 상각액
        V_SGF.AF_BOOK_AMT     := V_SGF.BF_BOOK_AMT + V_SGF.SANGGAK_AMT;
        --기말장부금액(EIR) = 기초장부금액(EIR) + 상각액(EIR)
        --<주의> 미상각잔액은 EIR기준 장부금액이 아닌 기초,기말장부금액을 계산하므로 기말장부금액(EIR)은 보정처리를 해도 액면금액과 일치할 수 없다. 
        V_SGF.AF_BOOK_AMT_EIR := V_SGF.BF_BOOK_AMT_EIR + V_SGF.SANGGAK_AMT_EIR;
        -- 미상각잔액 = 액면금액 - 기말장부금액
        V_SGF.MI_SANGGAK_AMT  := V_SGF.FACE_AMT - V_SGF.AF_BOOK_AMT;
      END IF;
      
      --<주의> 필드값 변경후 V_SGF를 SG_FLOWS에 다시 설정해야 Collection이 반영됨.
      O_EV_RET.SGF_LIST(IDX) := V_SGF;
      
      --이전상각스케쥴 = 현상각스케쥴
      V_BF_SGF := V_SGF;
      
      <<SKIP_LOOP>>  -- Continue 대용 GOTO 사용
      NULL;
    END LOOP; -- END OF FOR IDX IN 1..O_EV_RET.SGF_LIST.COUNT LOOP
    
    
    -- DB INSERT (BULK INSERT)
    -- EVENT_INFO 생성
    INSERT INTO EVENT_RESULT_NESTED_S VALUES O_EV_RET;
    
    --<NOT_DEF> 만기전 전부매도시에 매도일 이후의 상각스케쥴의 필드값은 액면금액이 0가 되므로 모두 0다.
    -- 전부매도시에 매도일 이후의 상각스케쥴을 전부 삭제해야 하는지는 아직 미정임.
    -- 만기 EVENT시에 대한 처리도 아직 미정
    
  END PR_APPLY_ADDTIONAL_EVENT;
  
  -- Create SangGak Flows (상각FLOWS 생성)
  FUNCTION FN_CREATE_SANGGAK_FLOWS(I_EIR_C EIR_CALC_INFO, I_CF_LIST TABLE_CF_S) RETURN TABLE_SGF_S IS
    -- Declare List <주의> TABLE OF TYPE은 반드시 초기화를 해야함.
    V_SGF_LIST     TABLE_SGF_S := TABLE_SGF_S();
    V_SGF          SGF_TYPE_S;
    V_BF_SGF       SGF_TYPE_S;
    V_COUNT        NUMBER  := 1;
    V_DATE         CHAR(8);
    V_LAST_DATE    CHAR(8); -- 해당월의 마지막일
    V_BF_INT_DATE  CHAR(8); -- 이전이자지급일
    V_LOG_STR      VARCHAR2(300); -- <LOG>
  BEGIN
    /* 상각스케쥴 생성 규칙
       1.취득일 ~ 만기일사이의 월결산, 기결산일 스케쥴 생성
       2.이표채는 이자수령일 스케쥴 생성
       3.일자기준으로 SORT
       4.기초장부금액,기말장부금액,유효이자,액면이자,실발생이자등을 LOOP를 돌며 설정.
         (만기일의 경우 미상각잔액 보정처리)
     */
    -- CashFlow List is strange (최소 취득,만기의 현금흐름은 있어야함)
    IF I_CF_LIST.COUNT < 2 THEN
      RAISE_APPLICATION_ERROR(-20011, 'Cash Flows is strange. COUNT['||I_CF_LIST.COUNT||']');
    END IF;
    
    -- 취득일 상각스케쥴
    PR_INIT_SGF(V_SGF); -- 초기화
    V_SGF.BASE_DATE    := I_EIR_C.EVENT_DATE; -- 기준일자 = 취득일자
    V_SGF.SEQ          := FN_GET_SGF_SEQ(V_SGF.BASE_DATE, V_SGF_LIST); -- <EVENT_SEQ> 동일 EVENT일의 상각 SEQ SET
    V_SGF.SANGGAK_TYPE := '1'; -- 1.매수
    -- Set to List
    -- <주의> TYPE의 TABLE일 경우에는 바로 할당하면 실행시 ora 6533 subscript beyond count 에러발생, EXTEND후에 SET 필요
    V_SGF_LIST.EXTEND;
    V_SGF_LIST(V_COUNT) := V_SGF;
    V_COUNT := V_COUNT+1;
    
    -- 만기일 상각스케쥴
    PR_INIT_SGF(V_SGF); -- 초기화
    V_SGF.BASE_DATE    := I_EIR_C.EXPIRE_DATE; -- 기준일자 = 만기일자
    V_SGF.SEQ          := FN_GET_SGF_SEQ(V_SGF.BASE_DATE, V_SGF_LIST); -- <EVENT_SEQ> 동일 EVENT일의 상각 SEQ SET
    V_SGF.SANGGAK_TYPE := '4'; -- 4.만기
    -- Set to List
    -- <주의> TYPE의 TABLE일 경우에는 바로 할당하면 실행시 ora 6533 subscript beyond count 에러발생, EXTEND후에 SET 필요
    V_SGF_LIST.EXTEND;
    V_SGF_LIST(V_COUNT) := V_SGF;
    V_COUNT := V_COUNT+1;
    
    --취득일 ~ 만기일사이의 월결산일,기결산일
    V_DATE := I_EIR_C.EVENT_DATE;
    LOOP
      V_LAST_DATE := TO_CHAR(LAST_DAY(TO_DATE(V_DATE,'YYYYMMDD')),'YYYYMMDD');
      --IF 월말 >= 만기일 THEN break (만기일의 상각스케쥴은 앞에서 Add함)
      IF V_LAST_DATE >= I_EIR_C.EXPIRE_DATE THEN
        EXIT;
      END IF;
      --IF 월말 > 기준일 이면 Add to List
      IF V_LAST_DATE > I_EIR_C.EVENT_DATE THEN
         PR_INIT_SGF(V_SGF); -- 초기화
         V_SGF.BASE_DATE  := V_LAST_DATE;
         V_SGF.SEQ        := FN_GET_SGF_SEQ(V_SGF.BASE_DATE, V_SGF_LIST); -- <EVENT_SEQ> 동일 EVENT일의 상각 SEQ SET
         IF SUBSTRB(V_LAST_DATE, 5,4) = '1231' THEN -- 기말
           V_SGF.SANGGAK_TYPE := '5'; -- 5.기결산
         ELSE
           V_SGF.SANGGAK_TYPE := '6'; -- 6.월결산
         END IF;
         -- Set to List
         -- <주의> TYPE의 TABLE일 경우에는 바로 할당하면 실행시 ora 6533 subscript beyond count 에러발생, EXTEND후에 SET 필요
         V_SGF_LIST.EXTEND;
         V_SGF_LIST(V_COUNT) := V_SGF;
         V_COUNT := V_COUNT+1;
      END IF;
      --다음월초로 이동
      V_DATE := TO_CHAR(TO_DATE(V_LAST_DATE,'YYYYMMDD') + 1, 'YYYYMMDD');
    END LOOP;
    
    --이표채 이자수령일 SET
    IF I_EIR_C.BOND_TYPE = '1' THEN
      -- 최초 이전일자 = 직전이자지급일
      V_BF_INT_DATE := FN_GET_BF_INT_DATE(I_EIR_C);
      LOOP
        -- 다음이자수령일 = 직전이자수령일 + 이자지급주기
        V_DATE := TO_CHAR(ADD_MONTHS(TO_DATE(V_BF_INT_DATE,'YYYYMMDD'), I_EIR_C.INT_CYCLE),'YYYYMMDD'); --다음 이자주기의 기준일
        -- IF 이자수령일 >= 만기일 THEN break; (만기일의 상각스케쥴은 앞에서 Add함)
        IF V_DATE >= I_EIR_C.EXPIRE_DATE THEN
          EXIT;
        END IF;
        
        --IF 이자수령일 > 기준일 THEN Add To List
        IF V_DATE > I_EIR_C.EVENT_DATE THEN
          PR_INIT_SGF(V_SGF); -- 초기화
          V_SGF.BASE_DATE    := V_DATE;
          V_SGF.SEQ          := FN_GET_SGF_SEQ(V_SGF.BASE_DATE, V_SGF_LIST); -- <EVENT_SEQ> 동일 EVENT일의 상각 SEQ SET
          V_SGF.SANGGAK_TYPE := '3'; -- 3.이자수령
          -- Set to List
          -- <주의> TYPE의 TABLE일 경우에는 바로 할당하면 실행시 ora 6533 subscript beyond count 에러발생, EXTEND후에 SET 필요
          V_SGF_LIST.EXTEND; 
          V_SGF_LIST(V_COUNT) := V_SGF;
          V_COUNT := V_COUNT+1;
        END IF;
        
        -- 이전일자 = 일자
        V_BF_INT_DATE := V_DATE;
      END LOOP;  
    END IF; -- END IF I_EIR_C.BOND_TYPE = '1' THEN
    
    --<LOG>
    --FOR IDX IN 1..V_SGF_LIST.COUNT LOOP
    --  V_LOG_STR := '[FN_CREATE_SANGGAK_FLOWS] BF SORT IDX['||IDX||'] BASE_DATE['||V_SGF_LIST(IDX).BASE_DATE||']';
    --  DBMS_OUTPUT.PUT_LINE(V_LOG_STR);
    --END LOOP;
    -- Sort SangGak Flows Order by BaseDate Asc
    PR_SORT_SANGGAK_FLOWS(V_SGF_LIST);
    --<LOG>
    --FOR IDX IN 1..V_SGF_LIST.COUNT LOOP
    --  V_LOG_STR := '[FN_CREATE_SANGGAK_FLOWS] AF SORT IDX['||IDX||'] BASE_DATE['||V_SGF_LIST(IDX).BASE_DATE||']';
    --  DBMS_OUTPUT.PUT_LINE(V_LOG_STR);
    --END LOOP;
    
    --이전 상각 스케쥴 (최초 list[1]
    V_BF_SGF := V_SGF_LIST(1);
    --액면금액 = 기준정보.발행금액
    V_BF_SGF.FACE_AMT        := I_EIR_C.FACE_AMT;
    --최초 기초장부금액 SET = 기준정보.장부금액
    V_BF_SGF.BF_BOOK_AMT     := I_EIR_C.BOOK_AMT;
    V_BF_SGF.BF_BOOK_AMT_EIR := I_EIR_C.BOOK_AMT;
    -- 기말 장부금액 = 기준정보.장부금액(최초)
    V_BF_SGF.AF_BOOK_AMT     := I_EIR_C.BOOK_AMT;
    V_BF_SGF.AF_BOOK_AMT_EIR := I_EIR_C.BOOK_AMT;
    --<주의> 필드값 변경후 V_BF_SGF를 SG_FLOWS에 다시 설정해야 Collection이 반영됨.
    V_SGF_LIST(1) := V_BF_SGF;
    
    FOR IDX IN 1..V_SGF_LIST.COUNT LOOP
      V_SGF := V_SGF_LIST(IDX);
      --상각일수 = 현상각스케쥴.일자 - 전상각스케쥴.일자
      V_SGF.DAYS      := FN_CALC_DAYS(V_BF_SGF.BASE_DATE, V_SGF.BASE_DATE);
      --액면금액 = 기준정보.발행금액
      V_SGF.FACE_AMT  := I_EIR_C.FACE_AMT;
      --기초장부금액 = 전상각스케쥴.기말장부금액
      V_SGF.BF_BOOK_AMT := V_BF_SGF.AF_BOOK_AMT;
      
      --액면이자 (단리,복리로 나누어 계산), 실 이자 발생기준이 아닌 계산기준
      IF I_EIR_C.BOND_TYPE = '4' THEN -- 4.복리채
        -- 현상각스케쥴.기준일자까지의 복리이자 - 전상각스케쥴.기준일자까지의 복리이자
        V_SGF.FACE_INT_AMT := FN_CALC_INT_OF_COMPOUND(I_EIR_C, V_SGF.BASE_DATE) - FN_CALC_INT_OF_COMPOUND(I_EIR_C, V_BF_SGF.BASE_DATE);
      ELSIF I_EIR_C.BOND_TYPE = '4' THEN -- 2.할인채
        --할인채는 액면이자 0
        V_SGF.FACE_INT_AMT := 0;
      ELSE -- 이표채,만기단리
        --단리 = 액면금액 * 이자율 * 일수/365
        V_SGF.FACE_INT_AMT := V_SGF.FACE_AMT * I_EIR_C.IR * V_SGF.DAYS/365;
        V_SGF.FACE_INT_AMT := FN_ROUND(V_SGF.FACE_INT_AMT); -- 금액 Round
      END IF;
      
      --유효이자 계산을 위한 값 설정
      --기초장부금액(EIR) = 전상각스케쥴.기말장부금액(EIR)
      V_SGF.BF_BOOK_AMT_EIR := V_BF_SGF.AF_BOOK_AMT_EIR;
      --유효이자 = 기초장부금액(EIR) * (POWER(1+ EIR, 일수/365) -1)
      V_SGF.EIR_INT_AMT := V_SGF.BF_BOOK_AMT_EIR * (POWER(1+I_EIR_C.EIR, V_SGF.DAYS/365) -1);
      V_SGF.EIR_INT_AMT := FN_ROUND(V_SGF.EIR_INT_AMT); -- 금액 Round
      
      --실발생이자 = CashFlow에서 해당기준일에 있는 이자금액(이자지급일 OR 만기일에 실제받는 이자)
      --<EVENT_SEQ> 동일 EVENT 일에 여러 EVENT 발생을 고려하여 실발생이자는 V_SGF.SANGGAK_TYPE = 3.이자수령 OR 4.만기 일 경우만 SET
      V_SGF.REAL_INT_AMT := 0;
      IF V_SGF.SANGGAK_TYPE IN ('3','4') THEN
        FOR JDX IN 1..I_CF_LIST.COUNT LOOP
          IF I_CF_LIST(JDX).BASE_DATE = V_SGF.BASE_DATE THEN
            V_SGF.REAL_INT_AMT := I_CF_LIST(JDX).INT_AMT;
            EXIT;
          END IF;
        END LOOP;
      END IF;
      
      --상각액 = 유효이자 - 액면이자
      V_SGF.SANGGAK_AMT     := V_SGF.EIR_INT_AMT - V_SGF.FACE_INT_AMT;
      --상각액(EIR) = 유효이자 - 실발생이자
      V_SGF.SANGGAK_AMT_EIR := V_SGF.EIR_INT_AMT - V_SGF.REAL_INT_AMT;
      --기말장부금액 = 기초장부금액 + 상각액
      V_SGF.AF_BOOK_AMT     := V_SGF.BF_BOOK_AMT + V_SGF.SANGGAK_AMT;
      --기말장부금액(EIR) = 기초장부금액(EIR) + 상각액(EIR)
      V_SGF.AF_BOOK_AMT_EIR := V_SGF.BF_BOOK_AMT_EIR + V_SGF.SANGGAK_AMT_EIR;
      -- 미상각잔액 = 액면금액 - 기말장부금액
      V_SGF.MI_SANGGAK_AMT  := V_SGF.FACE_AMT - V_SGF.AF_BOOK_AMT;
      
      --유효이자,액면이자 계산시 소수 2자리 절사로 인해, 만기시에도 미상각잔액이 남는다. 
      --따라서,만기일에 미상각잔액이 남아 있으면 해당 잔액을 0으로 하면서 유효이자,장부금액을 보정한다. 미상각잔액은 Clear
      --<EVENT_SEQ> 마지막의 판단 기준은 IDX = V_SGF_LIST.COUNT로 설정함. (동일한 기준일에 2개이상의 SGF가 들어갈 수 있음)
      --IF V_SGF.BASE_DATE = I_EIR_C.EXPIRE_DATE AND V_SGF.MI_SANGGAK_AMT <> 0 THEN
      IF IDX = V_SGF_LIST.COUNT AND V_SGF.MI_SANGGAK_AMT <> 0 THEN
        --잘못 계산하여 미상각잔액이 1이상이면 문제가 있는것임. (단수차가 아님)
        -- <FOR_KOREA_BOND> 절사에 의한 미상각잔액 10이상
        --IF ABS(V_SGF.MI_SANGGAK_AMT) >= 1 THEN
        IF ABS(V_SGF.MI_SANGGAK_AMT) >= 10 THEN
          RAISE_APPLICATION_ERROR(-20011, '만기일의 미상각잔액['||V_SGF.MI_SANGGAK_AMT||'] >= 10, 단수차 보정불가, 원인확인요');
        END IF;
        --<LOG>
        V_LOG_STR := '[FN_CREATE_SANGGAK_FLOWS] 만기 미상각잔액['||V_SGF.MI_SANGGAK_AMT||'] <> 0, 유효이자['||V_SGF.EIR_INT_AMT||']에 보정처리';
        DBMS_OUTPUT.PUT_LINE(V_LOG_STR);
        
        --유효이자 보정 : 유효이자 += 미상각잔액
        V_SGF.EIR_INT_AMT := V_SGF.EIR_INT_AMT + V_SGF.MI_SANGGAK_AMT;
        -- 상각액, 기말장부금액 다시 계산
        --상각액 = 유효이자 - 액면이자
        V_SGF.SANGGAK_AMT     := V_SGF.EIR_INT_AMT - V_SGF.FACE_INT_AMT;
        --상각액(EIR) = 유효이자 - 실발생이자
        V_SGF.SANGGAK_AMT_EIR := V_SGF.EIR_INT_AMT - V_SGF.REAL_INT_AMT;
        --기말장부금액 = 기초장부금액 + 상각액
        V_SGF.AF_BOOK_AMT     := V_SGF.BF_BOOK_AMT + V_SGF.SANGGAK_AMT;
        --기말장부금액(EIR) = 기초장부금액(EIR) + 상각액(EIR)
        --<주의> 미상각잔액은 EIR기준 장부금액이 아닌 기초,기말장부금액을 계산하므로 기말장부금액(EIR)은 보정처리를 해도 액면금액과 일치할 수 없다. 
        V_SGF.AF_BOOK_AMT_EIR := V_SGF.BF_BOOK_AMT_EIR + V_SGF.SANGGAK_AMT_EIR;
        -- 미상각잔액 = 액면금액 - 기말장부금액
        V_SGF.MI_SANGGAK_AMT  := V_SGF.FACE_AMT - V_SGF.AF_BOOK_AMT;
      END IF;
      
      --<주의> 필드값 변경후 V_SGF를 SG_FLOWS에 다시 설정해야 Collection이 반영됨.
      V_SGF_LIST(IDX) := V_SGF;
      
      --이전상각스케쥴 = 현상각스케쥴
      V_BF_SGF := V_SGF;
      
    END LOOP; -- END FOR IDX
    
    RETURN V_SGF_LIST;
    
  END FN_CREATE_SANGGAK_FLOWS;
  
  
  -- Simulate EIR (최초 EIR 찾기) -> I_EIR_C에 필드값을 설정할 수 없으므로 O_EIR OUT 추가함.
  FUNCTION FN_SIMULATE_EIR(I_EIR_C EIR_CALC_INFO, O_EIR OUT NUMBER) RETURN TABLE_CF_S IS
    V_CF_LIST      TABLE_CF_S;
    V_SAME_YN      CHAR(1) := 'N'; -- 현재가치합 = 장부금액 일치여부
    V_UNIT         NUMBER := 0;
    V_LOG_STR      VARCHAR2(300); -- <LOG>
    V_CF           CF_TYPE_S; -- <LOG>
    V_START_EIR    NUMBER := 0;
  BEGIN
    /* 유효이자율(EIR) 계산규칙
     * 1.기준정보를 가지고 CashFlow 리스트를 만든다.
     * 2.최초 EIR을 모르는 상태에서 액면이자율을 EIR로 적용하여 현재가치를 구한다.
     * 차이금액 = 현재가치합 - 장부금액
     * IF 차이금액 > 0 THEN 1%씩 늘여가며 차이금액1이 -가 되는 이자율을 찾는다.
     *    최초근사 EIR = IR + 차이비율 *(차이금액/(차이금액-차이금액1)
     * ELSIF 차이금액 < 0 THEN 1%씩 줄여가며 차이금액1이 +가 되는 이자율을 찾는다.
     *    최초근사 EIR = IR - 차이비율 *(차이금액/(차이금액-차이금액1)
     * 최오근사 EIR로 다시 차이금액을 구함. 이제는 0.1%씩 바꿔가며 위 과정을 반복한다.
     * 이 과정을 소수 6자리까지 한다. 정확히 0으로 되지 않으면 오차범위에서 종료 한다.
     */
    O_EIR := I_EIR_C.IR; -- EIR 초기화 = IR
     
    -- 현금흐름 생성
    V_CF_LIST := FN_CREATE_CASH_FLOWS(I_EIR_C);
    
    -- IF 현금흐름LIST.COUNT < 1 THEN Raise Error
    IF V_CF_LIST.COUNT < 1 THEN
      RAISE_APPLICATION_ERROR(-20011, 'Cannot create cash flows.');
    END IF;
    
    -- LOG
    FOR IDX IN V_CF_LIST.FIRST .. V_CF_LIST.LAST LOOP
      V_CF := V_CF_LIST(IDX);
      --<LOG>
      --V_LOG_STR := '[FN_SIMULATE_EIR] Af CreateCF IDX['||IDX||']발생일['||V_CF.BASE_DATE||']액면['||V_CF.FACE_AMT||']총일수['||V_CF.TOT_DAYS||']이자일수['||V_CF.INT_DAYS||']'||
      --             '이자금액['||V_CF.INT_AMT||']원금['||V_CF.PRC_AMT||']현재가치['||V_CF.CUR_VALUE||']';
      --DBMS_OUTPUT.PUT_LINE(V_LOG_STR);
    END LOOP;
    
    -- 최초 EIR = IR
    V_START_EIR := I_EIR_C.IR;
    -- 소수점 10자리까지 LOOP를 돌며 근사 EIR 찾기, IS_SAME이면 break
    FOR IDX IN 1..9 LOOP
      -- V_UNIT : 최초 0.01(1%)부터 0.001, 0.0001 순으로 설정
      V_UNIT := 0.1/POWER(10, IDX);
      V_SAME_YN := 'N';
      --PR_FIND_APPROXIMATE_EIR(I_BOOK_AMT IN NUMBER, I_DIF_LIMIT IN NUMBER, I_UNIT IN NUMBER, I_START_EIR IN NUMBER, O_CF_LIST IN OUT TABLE_CF_S, O_SAME_YN IN OUT CHAR, O_APPROX_EIR IN OUT NUMBER);
      --BookAmt(장부금액), DifLimit(오차한도), I_UNIT(가감할 소수자리), I_START_EIR(시작 EIR) , O_IS_SAME(현재가치합과 장부금액의 일치여부) O_APPROX_EIR(근사EIR)
      PR_FIND_APPROXIMATE_EIR(I_EIR_C.BOOK_AMT, I_EIR_C.ALLOWED_LIMIT, V_UNIT, V_START_EIR, V_CF_LIST, V_SAME_YN, O_EIR);
      -- <LOG>
      V_LOG_STR := '[FN_SIMULATE_EIR] UNIT['||V_UNIT||']시작EIR['||V_START_EIR||']근사EIR['||O_EIR||']V_SAME_YN['||V_SAME_YN||']';
      DBMS_OUTPUT.PUT_LINE(V_LOG_STR);
      
      -- IF 현가합 = 장부금액 THEN break
      IF V_SAME_YN = 'Y' THEN EXIT; END IF;
      
      -- 다음 LOOP EIR 설정
      V_START_EIR := O_EIR;
    END LOOP;
    
    RETURN V_CF_LIST;
  END FN_SIMULATE_EIR;

  -- Create Cash Flows
  FUNCTION FN_CREATE_CASH_FLOWS ( I_EIR_C EIR_CALC_INFO) RETURN TABLE_CF_S IS
    -- Declare List <주의> TABLE OF TYPE은 반드시 초기화를 해야함.
    V_CF_LIST      TABLE_CF_S := TABLE_CF_S();
    V_CF           CF_TYPE_S;
    V_BF_INT_DATE  CHAR(8) := I_EIR_C.ISSUE_DATE;   -- 직전이자지급일 = 발행일(최초)
    V_AF_INT_DATE  CHAR(8) := I_EIR_C.EXPIRE_DATE;  -- 직후이자지급일 = 만기일(최초)
    V_COUNT        NUMBER  := 1;
    V_LOG_STR      VARCHAR2(300); -- <LOG>
  BEGIN
    
    IF I_EIR_C.BOND_TYPE = '1' THEN --  이표채(Coupon)
      --직전이자지급일 GET
      LOOP
        V_AF_INT_DATE := TO_CHAR(ADD_MONTHS(TO_DATE(V_BF_INT_DATE,'YYYYMMDD'), I_EIR_C.INT_CYCLE),'YYYYMMDD'); --다음 이자주기의 기준일
        
        -- IF 직후이자지급일 > 기준일 THEN EXIT
        -- 기준일과 이자지급일이 같으면 직전이자지급일 = 취득일 <NOT_DEF> 실제 이표채 기준인지 확인요 
        IF V_AF_INT_DATE > I_EIR_C.EVENT_DATE THEN
           EXIT;
        END IF;
       
        -- Set AfIntDate To BfIntDate
        V_BF_INT_DATE := V_AF_INT_DATE;
      END LOOP;
      
      --RAISE_APPLICATION_ERROR(-20011,'AFTER LOOP EXIT V_CNT['||V_CNT||']V_BF_INT_DATE['||V_BF_INT_DATE||']V_AF_INT_DATE['||V_AF_INT_DATE||']I_EIR_C.EVENT_DATE['||I_EIR_C.EVENT_DATE||']');
      
      -- 기준일 CASH_FLOW
      PR_INIT_CF(V_CF); -- 초기화
      V_CF.BASE_DATE  := I_EIR_C.EVENT_DATE;
      V_CF.FACE_AMT   := I_EIR_C.FACE_AMT;
      -- Set to List
      -- <주의> TYPE의 TABLE일 경우에는 바로 할당하면 실행시 ora 6533 subscript beyond count 에러발생, EXTEND후에 SET 필요
      V_CF_LIST.EXTEND;
      V_CF_LIST(V_COUNT) := V_CF;
      V_COUNT := V_COUNT+1;
      
      --다음 지급일 Cash Flow 생성
      LOOP
        -- 다음 이자주기의 기준일
        V_AF_INT_DATE := TO_CHAR(ADD_MONTHS(TO_DATE(V_BF_INT_DATE,'YYYYMMDD'), I_EIR_C.INT_CYCLE),'YYYYMMDD'); --다음 이자주기의 기준일
        --IF 직후이자지급일 > 만기일 THEN break;
        IF V_AF_INT_DATE > I_EIR_C.EXPIRE_DATE THEN
          EXIT;
        END IF;
        -- Cash Flow 생성
        PR_INIT_CF(V_CF); -- 초기화
        V_CF.BASE_DATE  := V_AF_INT_DATE; -- 기준일 = 이자지급일
        V_CF.FACE_AMT   := I_EIR_C.FACE_AMT; -- 액면금액
        V_CF.TOT_DAYS   := FN_CALC_DAYS(I_EIR_C.EVENT_DATE, V_AF_INT_DATE); --누적일수 = 직후지급일 - 기준일
        V_CF.INT_DAYS   := FN_CALC_DAYS(V_BF_INT_DATE    , V_AF_INT_DATE); --이자일수 = 직후지급일 - 직전지급일
        --최초 이자일수 = 직후지급일 - 취득일
        IF V_CF.INT_DAYS > V_CF.TOT_DAYS THEN
          V_CF.INT_DAYS := V_CF.TOT_DAYS;
        END IF;
        --IF 직후지급일 = 만기일 THEN 액면금액 SET
        IF V_AF_INT_DATE = I_EIR_C.EXPIRE_DATE THEN
          V_CF.PRC_AMT := I_EIR_C.FACE_AMT;
        END IF;
        -- Set to List
        -- <주의> TYPE의 TABLE일 경우에는 바로 할당하면 실행시 ora 6533 subscript beyond count 에러발생, EXTEND후에 SET 필요
        V_CF_LIST.EXTEND;
        V_CF_LIST(V_COUNT) := V_CF;
        V_COUNT := V_COUNT+1;
        
        --Set AfIntDate To BfIntDate
        V_BF_INT_DATE := V_AF_INT_DATE;
      END LOOP;
    
    ELSE  -- 할인,만기단리,복리는 기준일과 만기일의 Cash Flow만 생성함.
     -- 기준일 CASH_FLOW
      PR_INIT_CF(V_CF); -- 초기화
      V_CF.BASE_DATE  := I_EIR_C.EVENT_DATE;
      V_CF.FACE_AMT   := I_EIR_C.FACE_AMT;
      -- Set to List
      -- <주의> TYPE의 TABLE일 경우에는 바로 할당하면 실행시 ora 6533 subscript beyond count 에러발생, EXTEND후에 SET 필요
      V_CF_LIST.EXTEND;
      V_CF_LIST(V_COUNT) := V_CF;
      V_COUNT := V_COUNT+1;
      
      -- 만기일 CashFlow
      PR_INIT_CF(V_CF); -- 초기화
      V_CF.BASE_DATE  := I_EIR_C.EXPIRE_DATE;
      V_CF.FACE_AMT   := I_EIR_C.FACE_AMT;
      V_CF.TOT_DAYS   := FN_CALC_DAYS(I_EIR_C.EVENT_DATE, I_EIR_C.EXPIRE_DATE); -- 총일수 = 기준일 ~ 만기일
      V_CF.INT_DAYS   := V_CF.TOT_DAYS; -- 이자일수 = 총일수 (만기일이므로 동일)
      V_CF.PRC_AMT    := I_EIR_C.FACE_AMT; -- 원금 = 액면금액
      -- Set to List
      -- <주의> TYPE의 TABLE일 경우에는 바로 할당하면 실행시 ora 6533 subscript beyond count 에러발생, EXTEND후에 SET 필요
      V_CF_LIST.EXTEND;
      V_CF_LIST(V_COUNT) := V_CF;
      V_COUNT := V_COUNT+1;
    END IF;
    
    --이자지급기준(단리,복리)에 따라 기준일의 이자금액 SET, 할인채는 이자계산 필요없음.
    --FOR IDX IN V_CF_LIST.FIRST .. V_CF_LIST.LAST LOOP
    FOR IDX IN 1..V_CF_LIST.COUNT LOOP
      V_CF := V_CF_LIST(IDX);
      --취득일 Cash Flow는 SKIP <주의> CONTINUE Keyword가 10g에서 없어 GOTO 문으로 사용
      IF V_CF.INT_DAYS = 0 THEN 
        GOTO SKIP_LOOP;
      END IF;
      --2.할인채 이자계산 필요없음.
      IF I_EIR_C.BOND_TYPE = '2' THEN  --<주의> CONTINUE Keyword가 10g에서 없어 GOTO 문으로 사용
        GOTO SKIP_LOOP;
      END IF;
         
      IF I_EIR_C.BOND_TYPE = '4' THEN -- 4.복리채
         -- 이자금액 = 총이자 - 경과이자
         V_CF.INT_AMT := FN_CALC_TOT_INT_OF_COMPOUND(I_EIR_C) - FN_CALC_ACCRUED_INT(I_EIR_C);
      ELSIF I_EIR_C.BOND_TYPE IN ('1','3') THEN -- 1.이표채, 3.단리채(만기일시)
        -- 이자금액 = 액면금액 * 액면이자율 * 이자일수/365
        V_CF.INT_AMT := V_CF.FACE_AMT * I_EIR_C.IR * V_CF.INT_DAYS/365;
        V_CF.INT_AMT := FN_ROUND(V_CF.INT_AMT); --  금액 Round
      END IF;
      
      --<LOG>
      --V_LOG_STR := '[FN_CREATE_CASH_FLOWS]3 IN LOOP IDX['||IDX||']발생일['||V_CF.BASE_DATE||']액면['||V_CF.FACE_AMT||']총일수['||V_CF.TOT_DAYS||']이자일수['||V_CF.INT_DAYS||']'||
      --             '이자금액['||V_CF.INT_AMT||']원금['||V_CF.PRC_AMT||']현재가치['||V_CF.CUR_VALUE||']V_INT_AMT['||V_INT_AMT||']';
      --DBMS_OUTPUT.PUT_LINE(V_LOG_STR);
      
      --<주의> Collection에서 꺼내온 V_CF에 필드값을 변경후에 다시 해당 Collection에 V_CF를 설정하지 않으면 변경된 V_CF의 데이타가 반영되지 않음. 
      -- V_CF의 필드값 변경후에 설정하지 않으면, LOOP Scope에서는 변경된 값이 LOG에 찍히나
      -- LOOP Scope 밖에서 값을 찍으면 변경된 필드값이 안찍힘, 반드시 필드값 UPDATE후에 다시 설정할 것.
      V_CF_LIST(IDX) := V_CF;
      
      <<SKIP_LOOP>>
      NULL;
    END LOOP;
    
    -- <LOG>
    /*
    FOR IDX IN 1..V_CF_LIST.COUNT LOOP
      V_CF := V_CF_LIST(IDX);
      --<LOG>
      V_LOG_STR := '[FN_CREATE_CASH_FLOWS] BF Return IDX['||IDX||']발생일['||V_CF.BASE_DATE||']액면['||V_CF.FACE_AMT||']총일수['||V_CF.TOT_DAYS||']이자일수['||V_CF.INT_DAYS||']'||
                   '이자금액['||V_CF.INT_AMT||']원금['||V_CF.PRC_AMT||']현재가치['||V_CF.CUR_VALUE||']';
      DBMS_OUTPUT.PUT_LINE(V_LOG_STR);
    END LOOP;
    */
    -- Return table of CASH_FLOW
    RETURN V_CF_LIST;
    
  END FN_CREATE_CASH_FLOWS;
  
  -- Calculation Days
  FUNCTION FN_CALC_DAYS(I_FR_DATE CHAR, I_TO_DATE CHAR) RETURN NUMBER IS
    T_DAYS NUMBER := 0;
  BEGIN
    RETURN TO_DATE(I_TO_DATE,'YYYYMMDD') - TO_DATE(I_FR_DATE,'YYYYMMDD');
  END FN_CALC_DAYS;
  
  -- Round Number(일단 소수 2자리까지 TRUNC 기준) -- 금액기준 통일
  FUNCTION FN_ROUND(I_NUM NUMBER) RETURN NUMBER IS
  BEGIN
    -- <FOR_KOREA_BOND> 소수점이하 절사
    RETURN TRUNC(I_NUM, 0);
    --RETURN TRUNC(I_NUM, 2);
  END FN_ROUND;
  
  -- Calculate Total Compound Interest (복리채 총이자계산) 발행일 ~ 만기일
  FUNCTION FN_CALC_TOT_INT_OF_COMPOUND(I_EIR_C EIR_CALC_INFO) RETURN NUMBER IS
    V_INT_DATE     CHAR(8) := I_EIR_C.ISSUE_DATE; -- 이자지급일 = 발행일(최초)
    V_INT_AMT      NUMBER := 0;
    V_INT_TIMES    NUMBER := 0; -- 이자지급횟수(발행 ~ 만기)
    V_CNT_PER_YEAR NUMBER := 12/I_EIR_C.INT_CYCLE; -- 년지급횟수(12/이자지급주기(월))
  BEGIN
    -- 4.복리채가 아니면 0 RETURN
    IF I_EIR_C.BOND_TYPE <> '4' THEN RETURN 0; END IF;
    -- 발행~만기까지의 이자지급횟수 GET
    LOOP
      V_INT_DATE := TO_CHAR(ADD_MONTHS(TO_DATE(V_INT_DATE,'YYYYMMDD'), I_EIR_C.INT_CYCLE),'YYYYMMDD'); --다음 이자주기의 기준일
      -- IF 이자일 > 만기일 THEN break
      IF V_INT_DATE > I_EIR_C.EXPIRE_DATE THEN
        EXIT;
      END IF;
      V_INT_TIMES := V_INT_TIMES + 1; -- 이자지급횟수 증가
    END LOOP;
    
    -- 이자금액 = 액면금액 * (1+ IR/년지급횟수)^복리횟수 - 액면금액
    V_INT_AMT := I_EIR_C.FACE_AMT * POWER(1 + I_EIR_C.IR/V_CNT_PER_YEAR, V_INT_TIMES) - I_EIR_C.FACE_AMT;
    V_INT_AMT := FN_ROUND(V_INT_AMT); -- 금액 Round
    
    RETURN V_INT_AMT;
    
  END FN_CALC_TOT_INT_OF_COMPOUND;
  
  -- Calculate Compound Interest (복리채 이자계산) 발행일 ~ 기준일까지
  FUNCTION FN_CALC_INT_OF_COMPOUND(I_EIR_C EIR_CALC_INFO, I_BASE_DATE CHAR) RETURN NUMBER IS
    V_BF_INT_DATE  CHAR(8) := I_EIR_C.ISSUE_DATE;  -- 직전이자지급일 = 발행일(최초)
    V_AF_INT_DATE  CHAR(8) := I_EIR_C.EXPIRE_DATE; -- 직후이자지급일 = 만기일(최초)
    V_INT_AMT      NUMBER := 0;
    V_INT_TIMES    NUMBER := 0; -- 이자지급횟수(발행 ~ 만기)
    V_CNT_PER_YEAR NUMBER := 12/I_EIR_C.INT_CYCLE; -- 년지급횟수(12/이자지급주기(월))
  BEGIN
    -- 4.복리채가 아니면 0 RETURN
    IF I_EIR_C.BOND_TYPE <> '4' THEN RETURN 0; END IF;
    -- IF 기준일 <= 발행일 THEN return 0
    IF I_BASE_DATE <= I_EIR_C.ISSUE_DATE THEN RETURN 0; END IF;
    -- IF 기준일 >= 만기일 THEN return 발행~만기까지의 전체복리이자
    IF I_BASE_DATE >= I_EIR_C.EXPIRE_DATE THEN
      RETURN FN_CALC_TOT_INT_OF_COMPOUND(I_EIR_C);
    END IF;
    
    -- 발행~기준일까지의 이자지급횟수 GET
    LOOP
      V_AF_INT_DATE := TO_CHAR(ADD_MONTHS(TO_DATE(V_BF_INT_DATE,'YYYYMMDD'), I_EIR_C.INT_CYCLE),'YYYYMMDD'); --다음 이자주기의 기준일
      -- IF 직후이자일 > 기준일 THEN break
      IF V_AF_INT_DATE > I_BASE_DATE THEN
        EXIT;
      END IF;
      -- Set AfIntDate To BfIntDate
      V_BF_INT_DATE := V_AF_INT_DATE;
      V_INT_TIMES   := V_INT_TIMES + 1; -- 이자지급횟수 증가
    END LOOP;
    --복리횟수 = (발행일~직전이자기준일까지의 횟수) + (기준일-직전이자기준일)/(직후이자기준일-직전이자기준일)
    --직전이자지준일 ~ 취득일까지는 일수로 안분한다.
    V_INT_TIMES := V_INT_TIMES + FN_CALC_DAYS(V_BF_INT_DATE, I_BASE_DATE) / FN_CALC_DAYS(V_BF_INT_DATE, V_AF_INT_DATE);
    
    -- 이자금액 = 액면금액 * (1+ IR/년지급횟수)^복리횟수 - 액면금액
    V_INT_AMT := I_EIR_C.FACE_AMT * POWER(1 + I_EIR_C.IR/V_CNT_PER_YEAR, V_INT_TIMES) - I_EIR_C.FACE_AMT;
    V_INT_AMT := FN_ROUND(V_INT_AMT); -- 금액 Round
    
    RETURN V_INT_AMT;
    
  END FN_CALC_INT_OF_COMPOUND;	
  
  -- Calculate Accrued Interest (경과이자 계산) 발행일 ~ 기준일까지
  FUNCTION FN_CALC_ACCRUED_INT(I_EIR_C EIR_CALC_INFO) RETURN NUMBER IS
    V_BF_INT_DATE  CHAR(8) := I_EIR_C.ISSUE_DATE;  -- 직전이자지급일 = 발행일(최초)
    V_AF_INT_DATE  CHAR(8) := I_EIR_C.EXPIRE_DATE; -- 직후이자지급일 = 만기일(최초)
    V_INT_AMT      NUMBER := 0;
    V_INT_DAYS     NUMBER := 0;
  BEGIN
    IF I_EIR_C.BOND_TYPE = '1' THEN -- 1.이표채
      -- 직전이자지급일,직후이자지급일 GET
      LOOP
        V_AF_INT_DATE := TO_CHAR(ADD_MONTHS(TO_DATE(V_BF_INT_DATE,'YYYYMMDD'), I_EIR_C.INT_CYCLE),'YYYYMMDD'); --다음 이자주기의 기준일
        -- IF 이자일 > 기준일 THEN break
        IF V_AF_INT_DATE > I_EIR_C.EVENT_DATE THEN
          EXIT;
        END IF;
        -- Set AfIntDate To BfIntDate
        V_BF_INT_DATE := V_AF_INT_DATE;
      END LOOP;
      -- 이자일수 = (직전이자지급일 ~ 기준일)
      V_INT_DAYS := FN_CALC_DAYS(V_BF_INT_DATE, I_EIR_C.EVENT_DATE);
      -- 이자금액 = 액면금액 * 이자율 * 이자일수/365
      V_INT_AMT := I_EIR_C.FACE_AMT * I_EIR_C.IR * V_INT_DAYS/365;
    ELSIF I_EIR_C.BOND_TYPE = '3' THEN  -- 3.단리채(만기일시)
      -- 이자일수 = 발행일 ~ 기준일
      V_INT_DAYS := FN_CALC_DAYS(I_EIR_C.ISSUE_DATE, I_EIR_C.EVENT_DATE);
      -- 이자금액 = 액면금액 * 이자율 * 이자일수/365
      V_INT_AMT := I_EIR_C.FACE_AMT * I_EIR_C.IR * V_INT_DAYS/365;
    ELSIF I_EIR_C.BOND_TYPE = '4' THEN  -- 4.복리채
      -- 이자금액 = 발행일 ~ 기준일까지의 복리이자
      V_INT_AMT := FN_CALC_INT_OF_COMPOUND(I_EIR_C, I_EIR_C.EVENT_DATE);
    END IF;
    -- 금액 Round
    RETURN FN_ROUND(V_INT_AMT);
  END FN_CALC_ACCRUED_INT;
  
  -- Get Just Before Int Date (직전이자지급일,YYYYMMDD)
  FUNCTION FN_GET_BF_INT_DATE(I_EIR_C EIR_CALC_INFO) RETURN CHAR IS
    V_BF_INT_DATE  CHAR(8) := I_EIR_C.ISSUE_DATE;  -- 직전이자지급일 = 발행일(최초)
    V_AF_INT_DATE  CHAR(8) := I_EIR_C.EXPIRE_DATE; -- 직후이자지급일 = 만기일(최초)
  BEGIN
    -- 이표채만 직전이자지급일 계산가능, 그외는 만기일에만 이자가 지급되므로 발행일로 SET
    IF I_EIR_C.BOND_TYPE = '1' THEN -- 1.이표채
      -- 직전이자지급일,직후이자지급일 GET
      LOOP
        V_AF_INT_DATE := TO_CHAR(ADD_MONTHS(TO_DATE(V_BF_INT_DATE,'YYYYMMDD'), I_EIR_C.INT_CYCLE),'YYYYMMDD'); --다음 이자주기의 기준일
        -- IF 이자일 > 기준일 THEN break
        IF V_AF_INT_DATE > I_EIR_C.EVENT_DATE THEN
          EXIT;
        END IF;
        -- Set AfIntDate To BfIntDate
        V_BF_INT_DATE := V_AF_INT_DATE;
      END LOOP;
    END IF;
    
    RETURN V_BF_INT_DATE;
  END FN_GET_BF_INT_DATE;
  
  -- Calculate Current Value
  -- I_EIR(유효이자율), O_CF_LIST(Cash Flow Collection, 필드값 변경 IN OUT), O_VALUE_SUM(현재가치의합)
  -- Function으로 구현시에 Collection의 필드값을 변경할 수 없음.
  PROCEDURE PR_CALC_CUR_VALUE(I_EIR IN NUMBER, O_CF_LIST IN OUT TABLE_CF_S, O_VALUE_SUM IN OUT NUMBER) IS
    V_TOT_CASH  NUMBER := 0; -- 총현금흐름 = 이자금액 + 원금액
    V_CF        CF_TYPE_S; -- Cash Flow Table Data Type
  BEGIN
    -- OUT INIT
    O_VALUE_SUM := 0;
    -- LOOP를 돌며 CashFlow의 현재가치를 구하고 SUM을 누적한다. 
    FOR IDX IN 1.. O_CF_LIST.COUNT LOOP
      -- CashFlow Item SET
      V_CF := O_CF_LIST(IDX);
      
      -- 총현금흐름 = 이자금액 + 원금 of CashFlow
      V_TOT_CASH := NVL(V_CF.INT_AMT,0) + NVL(V_CF.PRC_AMT,0);
      -- 전체현금흐름/POWER(1 + 유효이자율, 총일수(기준일-취득일)/365)
      V_CF.CUR_VALUE := V_TOT_CASH/POWER(1 + I_EIR, V_CF.TOT_DAYS/365);
      -- 금액 Round
      V_CF.CUR_VALUE := FN_ROUND(V_CF.CUR_VALUE);
      -- 현재가치합 누적
      O_VALUE_SUM := O_VALUE_SUM + V_CF.CUR_VALUE;
      --<주의> Collection에서 꺼내온 V_CF에 필드값을 변경후에 다시 해당 Collection에 V_CF를 설정하지 않으면 변경된 V_CF의 데이타가 반영되지 않음. 
      -- V_CF의 필드값 변경후에 설정하지 않으면, LOOP Scope에서는 변경된 값이 LOG에 찍히나
      -- LOOP Scope 밖에서 값을 찍으면 변경된 필드값이 안찍힘, 반드시 필드값 UPDATE후에 다시 설정할 것.
      O_CF_LIST(IDX) := V_CF;
    END LOOP;
  END PR_CALC_CUR_VALUE;
  
  -- Find Approximate EIR (근사 유효이자 구하기) 
  -- BookAmt(장부금액), DifLimit(오차한도), I_UNIT(가감할 소수자리), I_START_EIR(시작 EIR) , O_CF_LIST(CF Collection), O_SAME_YN(현재가치합과 장부금액의 일치여부), O_APPROX_EIR(근사 EIR)
  -- Trial And Error 방식으로 근사 EIR 구하기, Function으로는 Collection의 필드값 변경불가 , 프로시저로 처리함.
  PROCEDURE PR_FIND_APPROXIMATE_EIR(I_BOOK_AMT IN NUMBER, I_DIF_LIMIT IN NUMBER, I_UNIT IN NUMBER, I_START_EIR IN NUMBER, O_CF_LIST IN OUT TABLE_CF_S, O_SAME_YN IN OUT CHAR, O_APPROX_EIR IN OUT NUMBER) IS
    V_DIF_AMT       NUMBER := 0; -- 차이금액 = 현재가치합 - 장부금액
    V_DIF_AMT1      NUMBER := 0; -- 차이금액1 (변경된 EIR로 계산된 차이금액)
    V_CUR_VALUE_SUM NUMBER := 0; -- 현재가치합산
    V_LOOP_CNT      NUMBER := 0; -- LOOP 건수
    V_MAX_LOOP_CNT  NUMBER := 50; -- 최대 LOOP횟수 50
    V_IS_EXCEED_MAX BOOLEAN := FALSE; -- 최대 LOOP횟수 초과여부
    V_CALC_EIR      NUMBER := I_START_EIR; -- 계산 EIR (최초 I_START_EIR)
    V_SIGN          NUMBER := 1; -- Sign 증가 1, 감소 -1
  BEGIN
    -- Out INIT
    O_SAME_YN := 'N';
    O_APPROX_EIR := I_START_EIR;
    
    -- 현재가치의 합 계산
    --<TEST_RESULT> FN_CALC_CUR_VALUE_SUM으로 하면 Collection의 필드값을 변경하지 못함. Procedure로 변경함.
    --V_CUR_VALUE_SUM := FN_CALC_CUR_VALUE_SUM(I_CF_LIST, I_START_EIR);
    PR_CALC_CUR_VALUE(I_START_EIR, O_CF_LIST, V_CUR_VALUE_SUM);
    -- 차이금액 = 현가합 - 장부금액
    V_DIF_AMT := V_CUR_VALUE_SUM - I_BOOK_AMT;
    -- IF 차이금액 0 THEN 근사 EIR = 시작 EIR RETURN
    IF V_DIF_AMT = 0 THEN 
      O_SAME_YN := 'Y';
      O_APPROX_EIR := I_START_EIR;
      RETURN;
    END IF;
    
    -- IF 차이금액 < 0 THEN 부호 = -1 (EIR를 감소시키며 Trial And Error)
    IF V_DIF_AMT < 0 THEN  V_SIGN := -1; END IF;
    
    -- 계산 EIR를 I_UNIT만큼 계속 I_UNIT씩 증가,감소시켜서 차이금액과 부호가 반대가 되는 차이금액이 되는 EIR을 찾는다.
    LOOP
      -- 계산 EIR += 부호*가감숫자단위
      V_CALC_EIR := V_CALC_EIR + V_SIGN * I_UNIT;
      -- EIR 정합성확인  0 < calcEIR < 1 (%단위가 아닌 소수단위)
      IF V_CALC_EIR <= 0 OR V_CALC_EIR >= 1 THEN
        RAISE_APPLICATION_ERROR(-20011, 'EIR['||V_CALC_EIR||'] is strange. Rule :0 < EIR < 1, I_START_EIR['||I_START_EIR||']UNIT['||I_UNIT||']V_SIGN['||V_SIGN||']BOOK_AMT['||I_BOOK_AMT||']LOOP_CNT['||V_LOOP_CNT||']');
      END IF;
      -- 차이금액1 = I_CALC_EIR로 계산한 현가합 - 장부금액
      PR_CALC_CUR_VALUE(V_CALC_EIR, O_CF_LIST, V_CUR_VALUE_SUM);
      V_DIF_AMT1 := V_CUR_VALUE_SUM - I_BOOK_AMT;
      -- IF 차이금액1 = 0 THEN V_CALC_EIR를 RETURN
      IF V_DIF_AMT1 = 0 THEN
        O_SAME_YN    := 'Y';
        O_APPROX_EIR := V_CALC_EIR;
        RETURN;
      END IF;
      
      -- IF SIGN(차이금액) <> SIGN(차이금액1) THEN break; 
      -- 차이금액이 반대부호가 되는 CALC_EIR에서 LOOP STOP
      IF SIGN(V_DIF_AMT) <> SIGN(V_DIF_AMT1) THEN
        EXIT;
      END IF;
      
      -- IF LOOP_CNT == MAX_LOOP_CNT THEN break
      IF V_LOOP_CNT = V_MAX_LOOP_CNT THEN
        V_IS_EXCEED_MAX := TRUE;
        EXIT;
      END IF;
      -- LOOP_CNT 증가
      V_LOOP_CNT := V_LOOP_CNT + 1;
      
    END LOOP;
    
    --최대 LOOP횟수를 초과(차이가 너무작아 역방향이 나오지 않음)해도 diffLimit보다 diffAmt가 작으면 startEIR로 return
    --<TEST_RESULT> 테스트 결과 보통 5회이내에 차이금액이 반대 SIGN인 EIR을 찾음.
    IF V_IS_EXCEED_MAX THEN
      -- IF 차이금액 > 오차한도 THEN 에러처리 
      IF V_DIF_AMT > I_DIF_LIMIT THEN
        RAISE_APPLICATION_ERROR(-20011, 'EIR Calculation Error, Diff_Amt['||V_DIF_AMT||'] > Diff_Limit['||I_DIF_LIMIT||']');
      ELSE
        O_APPROX_EIR := I_START_EIR;
        RETURN;
      END IF;
    END IF;
    
    --근사 EIR = 시작EIR + 차이비율(종료EIR-시작EIR) *(차이금액/(차이금액-차이금액1)
    O_APPROX_EIR := I_START_EIR + (V_CALC_EIR - I_START_EIR) * V_DIF_AMT /(V_DIF_AMT - V_DIF_AMT1);
    --근사 EIR 소수점 이하 10자리에서 절사 로직
    O_APPROX_EIR := TRUNC(O_APPROX_EIR, 10);
    
  END PR_FIND_APPROXIMATE_EIR;
  
  -- Cash Flow, SangGak Flow 초기화 프로시저
  PROCEDURE PR_INIT_CF (O_CF  IN OUT CF_TYPE_S) IS
  BEGIN
    -- TYPE INITIALIZE
    O_CF := CF_TYPE_S('00000000',0,0,0,0,0,0);
    /* TYPE을 생성하지 않고 필드를 초기화 하면 실행시 Ora-6530 에러 발생, 초기화되지 않은 조합을 참조
    -- 일자는 00000000, TYPE = 1, 금액, 비율 = 0
    O_CF.BASE_DATE  := '00000000';
    O_CF.FACE_AMT   := 0;
    O_CF.TOT_DAYS   := 0;
    O_CF.INT_DAYS   := 0; 
    O_CF.INT_AMT    := 0; 
    O_CF.PRC_AMT    := 0; 
    O_CF.CUR_VALUE  := 0;
    */ 
  END PR_INIT_CF;
  PROCEDURE PR_INIT_SGF(O_SGF IN OUT SGF_TYPE_S) IS
  BEGIN
    -- TYPE INITIALIZE
    O_SGF := SGF_TYPE_S('00000000',1,'1', 0,0,0,0,0,0,0,0,0,0,0,0);
    /* TYPE을 생성하지 않고 필드를 초기화 하면 실행시 Ora-6530 에러 발생, 초기화되지 않은 조합을 참조
    -- 일자는 00000000, TYPE = 1, 금액, 비율 = 0
    O_SGF.BASE_DATE       := '00000000';
    O_SGF.SANGGAK_TYPE    := '1';
    O_SGF.DAYS            := 0;
    O_SGF.FACE_AMT        := 0; 
    O_SGF.BF_BOOK_AMT     := 0; 
    O_SGF.EIR_INT_AMT     := 0; 
    O_SGF.FACE_INT_AMT    := 0; 
    O_SGF.SANGGAK_AMT     := 0; 
    O_SGF.AF_BOOK_AMT     := 0; 
    O_SGF.MI_SANGGAK_AMT  := 0; 
    O_SGF.BF_BOOK_AMT_EIR := 0; 
    O_SGF.REAL_INT_AMT    := 0; 
    O_SGF.SANGGAK_AMT_EIR := 0; 
    O_SGF.AF_BOOK_AMT_EIR := 0;
    */ 
  END PR_INIT_SGF;
  
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
  
  -- 해당채권잔고의 마지막 Event 정보 Load (DB에서 데이타를 읽어서 마지막 EVENT_RESULT를 Load한다.
  FUNCTION FN_GET_LAST_EVELT_RESULT(I_EV_INFO EVENT_INFO_TYPE) RETURN EVENT_RESULT_NESTED_S%ROWTYPE IS
    V_LAST_ER EVENT_RESULT_NESTED_S%ROWTYPE; -- 최종 EVENT 정보
    V_LOG_STR VARCHAR2(300); -- <LOG>
    -- 최종 EVENT 정보 GET (EVENT_DATE DESC로 처리 <NOT_DEF> 동일한 날의 두개이상의 EVENT 발생은 좀 더 고민
    CURSOR C_EV_RET_NESTED_CUR IS
    SELECT A.*
      FROM (SELECT * 
              FROM EVENT_RESULT_NESTED_S
             WHERE BOND_CODE = I_EV_INFO.BOND_CODE
               AND BUY_DATE  = I_EV_INFO.BUY_DATE
             ORDER BY EVENT_DATE DESC, EVENT_SEQ DESC ) A  -- <EVENT_SEQ> EVENT_DATE, EVENT_SEQ DESC
     WHERE ROWNUM = 1;
  BEGIN
    
    -- 최종EVENT 정보 GET
    OPEN C_EV_RET_NESTED_CUR;
    FETCH C_EV_RET_NESTED_CUR INTO V_LAST_ER;
    IF C_EV_RET_NESTED_CUR%NOTFOUND THEN
      CLOSE C_EV_RET_NESTED_CUR;
      RAISE_APPLICATION_ERROR(-20011, '최종 EVENT 정보가 없습니다.(추가 Event처리불가)');
    END IF;
    CLOSE C_EV_RET_NESTED_CUR;
    
    --<LOG>
    V_LOG_STR := '[FN_GET_LAST_EVELT_RESULT] EVENT_DATE['||V_LAST_ER.EVENT_DATE||']EVENT_SEQ['||V_LAST_ER.EVENT_SEQ||']EVENT_TYPE['||V_LAST_ER.EVENT_TYPE||']';
    --RAISE_APPLICATION_ERROR(-20011, V_LOG_STR);
    DBMS_OUTPUT.PUT_LINE(V_LOG_STR);
    
    RETURN V_LAST_ER;
  END FN_GET_LAST_EVELT_RESULT;
  
  -- 해당Event정보로 EIR_CALC_INFO GET
  FUNCTION FN_GET_EIR_CALC_INFO(I_EV_INFO EVENT_INFO_TYPE) RETURN EIR_CALC_INFO IS
    V_EIR_C EIR_CALC_INFO; -- Event Calculation Info
    -- 채권정보 CURSOR
    CURSOR C_BINFO_CUR IS
    SELECT BOND_TYPE
          ,ISSUE_DATE
          ,EXPIRE_DATE
          ,INT_CYCLE
          ,ALLOWED_LIMIT
      FROM BOND_INFO
     WHERE BOND_CODE = I_EV_INFO.BOND_CODE;
    C_BINFO C_BINFO_CUR%ROWTYPE; 
  BEGIN
    -- 채권정보 OPEN
    OPEN C_BINFO_CUR;
    FETCH C_BINFO_CUR INTO C_BINFO;
    IF C_BINFO_CUR%NOTFOUND THEN
      CLOSE C_BINFO_CUR;
      RAISE_APPLICATION_ERROR(-20011, '채권코드['||I_EV_INFO.BOND_CODE||']의 정보가 없습니다.');
    END IF;
    CLOSE C_BINFO_CUR;
    
    -- I_EV_INFO로 V_EIR_C 설정
    V_EIR_C.EVENT_DATE  := I_EV_INFO.EVENT_DATE;
    V_EIR_C.IR          := I_EV_INFO.IR;
    V_EIR_C.EIR         := I_EV_INFO.EIR;
    V_EIR_C.FACE_AMT    := I_EV_INFO.FACE_AMT;
    V_EIR_C.BOOK_AMT    := I_EV_INFO.BOOK_AMT;
  
    -- 채권정보로 필드값 설정
    V_EIR_C.BOND_TYPE     := C_BINFO.BOND_TYPE;
    V_EIR_C.ISSUE_DATE    := C_BINFO.ISSUE_DATE;
    V_EIR_C.EXPIRE_DATE   := C_BINFO.EXPIRE_DATE;
    V_EIR_C.INT_CYCLE     := C_BINFO.INT_CYCLE;
    V_EIR_C.ALLOWED_LIMIT := C_BINFO.ALLOWED_LIMIT;
  
    -- 채권종목정보,채권잔고에서 조회하여 값 설정
    RETURN V_EIR_C;
  END FN_GET_EIR_CALC_INFO;
  
  -- EVENT_RESULT_NESTED_S에서 동일 EVENT일의 MAX + 1 SEQ GET
  FUNCTION FN_GET_EVENT_SEQ(I_EV_INFO EVENT_INFO_TYPE) RETURN NUMBER IS
    V_EVENT_SEQ NUMBER := 1;
  BEGIN
    -- EVENT_RESULT_NESTED_S TABLE에서 해당 BOND_CODE, BUY_DATE, EVENT_DATE의 MAX 순번 + 1 GET
    FOR C1 IN (SELECT NVL(MAX(EVENT_SEQ),0) + 1 SEQ
                 FROM EVENT_RESULT_NESTED_S
                WHERE BOND_CODE  = I_EV_INFO.BOND_CODE
                  AND BUY_DATE   = I_EV_INFO.BUY_DATE
                  AND EVENT_DATE = I_EV_INFO.EVENT_DATE ) LOOP
                  
      V_EVENT_SEQ := C1.SEQ;            
    END LOOP;
    RETURN V_EVENT_SEQ;
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
  
  -- 객체 STRING 함수
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
  
  -- 30/360 기준 일수 계산
  FUNCTION FN_CALC_DAYS_30360(I_FR_DATE CHAR, I_TO_DATE CHAR, I_TYPE CHAR, I_EXPIRE_DATE CHAR) RETURN NUMBER IS
    T_DAYS NUMBER := 0;
    T_FR_DATE  DATE := TO_DATE(I_FR_DATE,'YYYYMMDD');
    T_TO_DATE  DATE := TO_DATE(I_TO_DATE,'YYYYMMDD');
    T_DAY1     NUMBER := 0;
    T_DAY2     NUMBER := 0;
    T_LAST_DATE CHAR(8) ; -- 최종일
  BEGIN
   /* 30/360 RULE (BY http://en.wikipedia.org/wiki/Day_count_convention#Comparison_of_30.2F360_and_Actual.2F360)
    Date1 (Y1.M1.D1) Starting date for the accrual. It is usually the coupon payment date preceding Date2.
    Date2 (Y2.M2.D2) Date through which interest is being accrued. You could word this as the "to" date, with Date1 as the "from" date. For a bond trade, it is the settlement date of the trade.
    Interest(단리기준) = Principal * CouponRate * Factor
    Factor = (360*(Y2 - Y1) + 30*(M2 - M1) + (D2 - D1))/360
    Days = 360*(Y2 - Y1) + 30*(M2 - M1) + (D2 - D1)
    
    TYPE = 1.30/360 US
    Date adjustment rules (more than one may taTke effect; apply them in order, and if a date is changed in one rule the changed value is used in the following rules):
    EOM : Indicates that the investment always pays interest on the last day of the month. If the investment is not EOM, it will always pay on the same day of the month (e.g., the 10th).
    If the investment is EOM and (Date1 is the last day of February) and (Date2 is the last day of February), then change D2 to 30.
    If the investment is EOM and (Date1 is the last day of February), then change D1 to 30.
    If D2 is 31 and D1 is 30 or 31, then change D2 to 30.
    If D1 is 31, then change D1 to 30.
    <Formula> <NOT_DEF> EOM은 반영하지 않음.
    If (DAY1=31) Then Set D1=30	 Else set D1=DAY1	
    If (DAY2=31) and (DAY1=30 or 31) Then set D2=30	Else set D2=DAY2

    TYPE = 2.30E/360 (E :EuroBond)
    If D1 is 31, then change D1 to 30.
    If D2 is 31, then change D2 to 30.
    <Formula>
    If (DAY1=31) Then Set D1=30	Else set D1=DAY1	
	If (DAY2=31) Then set D2=30	Else set D2=DAY2	

    TYPE = 3.30E/360 ISDA (International Swaps and Derivatives Association)
    If D1 is the last day of the month, then change D1 to 30.
    If D2 is the last day of the month (unless Date2 is the maturity date and M2 is February), then change D2 to 30.
    <Formula>
    If DAY1 is last day of Month Then Set D1=30 Otherwise set D1=DAY1
    IF DAY2 is Last day of Month And (Not maturity date Or Not M2 is Feb) Then set D2=30 Otherwise set D2=DAY2
   */
   -- Year 적용
   T_DAYS := (TO_NUMBER(TO_CHAR(T_TO_DATE,'YYYY')) - TO_NUMBER(TO_CHAR(T_FR_DATE,'YYYY'))) * 360;
   --Month 적용
   T_DAYS := T_DAYS + (TO_NUMBER(TO_CHAR(T_TO_DATE,'MM')) - TO_NUMBER(TO_CHAR(T_FR_DATE,'MM'))) * 30;
   -- Day 적용
   T_DAY1 := TO_NUMBER(TO_CHAR(T_FR_DATE,'DD'));
   T_DAY2 := TO_NUMBER(TO_CHAR(T_TO_DATE,'DD'));
   
   IF I_TYPE = '1' THEN -- 1.30/360 US
     IF T_DAY1 = 31 THEN
       T_DAY1 := 30;
     END IF;
     IF T_DAY2 = 31 AND T_DAY1 IN (30,31) THEN
       T_DAY2 := 30;
     END IF;
   ELSIF I_TYPE = '2' THEN -- 2.30E/360
     IF T_DAY1 = 31 THEN
       T_DAY1 := 30;
     END IF;
     IF T_DAY2 = 31 THEN
       T_DAY2 := 30;
     END IF;
   ELSIF I_TYPE = '3' THEN -- 3.30E/360 ISDA
     -- T_FR_DATE의 LAST_DAY
     T_LAST_DATE := TO_CHAR(LAST_DAY(T_FR_DATE),'YYYYMMDD');
     IF I_FR_DATE = T_LAST_DATE THEN
       T_DAY1 := 30;
     END IF;
     -- T_TO_DATE의 LAST_DAY
     T_LAST_DATE := TO_CHAR(LAST_DAY(T_TO_DATE),'YYYYMMDD');
     -- 최종일 AND (NOT 만기일 OR NOT 2월) THEN Set 30
     IF I_TO_DATE = T_LAST_DATE THEN
       IF I_TO_DATE <> I_EXPIRE_DATE OR TO_CHAR(T_TO_DATE,'MM') <> '02' THEN
         T_DAY2 := 30;
       END IF;
     END IF;
   ELSE
     RAISE_APPLICATION_ERROR(-20011, 'Invalid Calculation Type['||I_TYPE||'] Valid Types is 1,2,3.');
   END IF;
   -- Day적용
   T_DAYS := T_DAYS + (T_DAY2 - T_DAY1);
   
   RETURN T_DAYS;
  END FN_CALC_DAYS_30360;
  
  
END PKG_EIR_NESTED_S;
/

