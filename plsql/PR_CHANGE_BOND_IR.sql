CREATE OR REPLACE PROCEDURE ISS.PR_CHANGE_BOND_IR (
  I_CHANGE_INFO IN  CHANGE_BOND_IR_INFO_TYPE  -- TYPE : 이자율 변경 정보
, O_BOND_TRADE  OUT BOND_TRADE%ROWTYPE        -- ROWTYPE : 거래내역
) IS
  -- TYPE
  T_EVENT_INFO      EVENT_INFO_TYPE;          -- TYPE    : 이벤트 INPUT
  T_EVENT_RESULT    EVENT_RESULT_EIR%ROWTYPE; -- ROWTYPE : 이벤트 OUTPUT
  T_BOND_BALANCE    BOND_BALANCE%ROWTYPE; -- ROWTYPE : 잔고
  
  -- CURSOR : 잔고
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_CHANGE_INFO.TRD_DATE   -- 거래일자(잔고 PK)
       AND FUND_CODE = I_CHANGE_INFO.FUND_CODE  -- 펀드코드(잔고 PK)
       AND BOND_CODE = I_CHANGE_INFO.BOND_CODE  -- 종목코드(잔고 PK)
       AND BUY_DATE  = I_CHANGE_INFO.BUY_DATE   -- 매수일자(잔고 PK)
       AND BUY_PRICE = I_CHANGE_INFO.BUY_PRICE  -- 매수단가(잔고 PK)
       AND BALAN_SEQ = I_CHANGE_INFO.BALAN_SEQ  -- 잔고일련번호(잔고 PK)
       FOR UPDATE;
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)입력값 검증(INPUT 필드)
  --   TRD_DATE   -- 거래일자(잔고 PK)
  --   FUND_CODE  -- 펀드코드(잔고 PK)
  --   BOND_CODE  -- 종목코드(잔고 PK)
  --   BUY_DATE   -- 매수일자(잔고 PK)
  --   BUY_PRICE  -- 매수단가(잔고 PK)
  --   BALAN_SEQ  -- 잔고일련번호(잔고 PK)
  --   BOND_IR    -- 표면이자율
  ----------------------------------------------------------------------------------------------------
  -- 표면이자율
  IF I_CHANGE_INFO.BOND_IR <= 0 THEN
    PCZ_RAISE(-20999, '표면이자율 오류');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)잔고 확인
  --   * 잔고 유무 확인
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_BALANCE_CUR;
    FETCH C_BOND_BALANCE_CUR INTO T_BOND_BALANCE;
    IF C_BOND_BALANCE_CUR%NOTFOUND THEN
      CLOSE C_BOND_BALANCE_CUR;
      RAISE_APPLICATION_ERROR(-20011, '잔고 오류');
    END IF;
  CLOSE C_BOND_BALANCE_CUR;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3)변수초기화
  --   * Object들을 초기화 및 Default값으로 설정함
  ----------------------------------------------------------------------------------------------------
  PKG_EIR_NESTED_NSC.PR_EVENT_INFO_TYPE_INIT(T_EVENT_INFO);
  PR_INIT_BOND_TRADE(O_BOND_TRADE);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)이자율 변경 처리 프로시져 호출
  --   * INPUT 설정
  --   * 금리변경 이벤트 생성, 현금흐름, EIR, 상각표 재산출
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := I_CHANGE_INFO.FUND_CODE; -- 펀드코드(잔고 PK)
  T_EVENT_INFO.BOND_CODE  := I_CHANGE_INFO.BOND_CODE; -- 종목코드(잔고 PK)
  T_EVENT_INFO.BUY_DATE   := I_CHANGE_INFO.BUY_DATE;  -- 매수일자(잔고 PK)
  T_EVENT_INFO.BUY_PRICE  := I_CHANGE_INFO.BUY_PRICE; -- 매수단가(잔고 PK)
  T_EVENT_INFO.BALAN_SEQ  := I_CHANGE_INFO.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
  T_EVENT_INFO.EVENT_DATE := I_CHANGE_INFO.TRD_DATE;  -- 이벤트일
  T_EVENT_INFO.IR         := I_CHANGE_INFO.BOND_IR;   -- 표면이자율
  
  PKG_EIR_NESTED_NSC.PR_APPLY_CHANG_IR_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5)EIR정보 잔고반영
  --   * 금리변경시 수정되는 정보
  --   * IR, EIR, 장부금액, 장부원가, 경과이자, ...
  ----------------------------------------------------------------------------------------------------
  T_BOND_BALANCE.BOND_IR      := T_EVENT_RESULT.IR;  -- 표면이자율
  T_BOND_BALANCE.BOND_EIR     := T_EVENT_RESULT.EIR; -- 유효이자율
  --T_BOND_BALANCE.BOOK_AMT     := ;                   -- 장부금액
  --T_BOND_BALANCE.BOOK_PRC_AMT := ;                   -- 장부원가
  --T_BOND_BALANCE.ACCRUED_INT  := ;                   -- 경과이자
  
  
  -- UPDATE : 잔고 업데이트
  UPDATE BOND_BALANCE 
     SET ROW = T_BOND_BALANCE
   WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- 영업일자(잔고 PK)
     AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- 펀드코드(잔고 PK)
     AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- 종목코드(잔고 PK)
     AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- 매수일자(잔고 PK)
     AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- 매수단가(잔고 PK)
     AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
  
  
  
  DBMS_OUTPUT.PUT_LINE('PR_CHANGE_BOND_IR END');
  
END;