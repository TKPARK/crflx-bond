CREATE OR REPLACE PROCEDURE ISS.PR_CANCEL_BOND (
  I_CANCEL_INFO IN  CANCEL_INFO_TYPE_S         -- TYPE    : 취소정보
, O_BOND_TRADE  OUT BOND_TRADE%ROWTYPE         -- ROWTYPE : 거래내역
) IS
  -- CURSOR : 원거래내역
  CURSOR C_ORGN_BOND_TRADE_CUR IS
    SELECT *
      FROM BOND_TRADE
     WHERE TRD_DATE = I_CANCEL_INFO.TRD_DATE   -- 거래일자(거래내역 PK)
       AND TRD_SEQ  = I_CANCEL_INFO.TRD_SEQ;   -- 거래일련번호(거래내역 PK)
  -- CURSOR : 잔고
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_SELL_INFO.TRD_DATE    -- 거래일자(잔고 PK)
       AND FUND_CODE = I_SELL_INFO.FUND_CODE   -- 펀드코드(잔고 PK)
       AND BOND_CODE = I_SELL_INFO.BOND_CODE   -- 종목코드(잔고 PK)
       AND BUY_DATE  = I_SELL_INFO.BUY_DATE    -- 매수일자(잔고 PK)
       AND BUY_PRICE = I_SELL_INFO.BUY_PRICE   -- 매수단가(잔고 PK)
       AND BALAN_SEQ = I_SELL_INFO.BALAN_SEQ   -- 잔고일련번호(잔고 PK)
       FOR UPDATE;
  -- TYPE
  T_EVENT_INFO      PKG_EIR_NESTED_NSC.EVENT_INFO_TYPE; -- TYPE    : 이벤트 INPUT
  T_EVENT_RESULT    EVENT_RESULT_NESTED_S%ROWTYPE;      -- ROWTYPE : 이벤트 OUTPUT
  T_BOND_BALANCE    BOND_BALANCE%ROWTYPE;               -- ROWTYPE : 잔고
  T_ORGN_BOND_TRADE BOND_TRADE%ROWTYPE;                 -- ROWTYPE : 원거래내역
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)입력값 검증(INPUT 필드)
  --   TRD_DATE   -- 거래일자(거래내역 PK)
  --   TRD_SEQ    -- 거래일련번호(거래내역 PK)
  --   EVENT_TYPE -- Event 종류(1.매수, 2.매도)
  ----------------------------------------------------------------------------------------------------
  -- 거래일자
  IF I_CANCEL_INFO.TRD_DATE <> TO_CHAR(SYSDATE, 'YYYYMMDD') THEN
    RAISE_APPLICATION_ERROR(-20999, '거래일자 오류');
  END IF;
  -- 거래일련번호
  IF I_CANCEL_INFO.TRD_SEQ <= 0 THEN
    RAISE_APPLICATION_ERROR(-20999, '거래일련번호 오류');
  END IF;
  -- Event 종류
  IF I_CANCEL_INFO.EVENT_TYPE <> '1' OR I_CANCEL_INFO.EVENT_TYPE <> '2' THEN
    RAISE_APPLICATION_ERROR(-20999, 'Event 종류 오류');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)취소대상 확인
  --   * 원거래내역 조회
  --   * 잔고 조회
  ----------------------------------------------------------------------------------------------------
  OPEN C_ORGN_BOND_TRADE_CUR;
    FETCH C_ORGN_BOND_TRADE_CUR INTO T_ORGN_BOND_TRADE;
    IF C_ORGN_BOND_TRADE_CUR%NOTFOUND THEN
      CLOSE C_ORGN_BOND_TRADE_CUR;
      RAISE_APPLICATION_ERROR(-20011, '원거래내역 오류');
    END IF;
  CLOSE C_ORGN_BOND_TRADE_CUR;
  
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
  T_EVENT_INFO   := PKG_EIR_NESTED_NSC.FN_INIT_EVENT_INFO();
  T_EVENT_RESULT := FN_INIT_EVENT_RESULT();
  O_BOND_TRADE   := FN_INIT_BOND_TRADE();
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)취소 처리 프로시져 호출
  --   * INPUT 설정
  --   * 
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := T_BOND_BALANCE.FUND_CODE; -- 펀드코드(잔고 PK)
  T_EVENT_INFO.BOND_CODE  := T_BOND_BALANCE.BOND_CODE; -- 종목코드(잔고 PK)
  T_EVENT_INFO.BUY_DATE   := T_BOND_BALANCE.BIZ_DATE;  -- 매수일자(잔고 PK)
  T_EVENT_INFO.BUY_PRICE  := T_BOND_BALANCE.BUY_PRICE; -- 매수단가(잔고 PK)
  T_EVENT_INFO.BALAN_SEQ  := T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
  T_EVENT_INFO.EVENT_DATE := I_CANCEL_INFO.TRD_DATE;   -- 이벤트일
  T_EVENT_INFO.EVENT_TYPE := I_CANCEL_INFO.EVENT_TYPE; -- Event종류(1.매수, 2.매도)
  
  --PKG_EIR_NESTED_NSC.PR_APPLY_ADD_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5)잔고 복구
  --   * 1.매수 : 잔고 삭제
  --   * 2.매도 : 매도전 잔고로 복구
  ----------------------------------------------------------------------------------------------------
  IF I_CANCEL_INFO.EVENT_TYPE = '1' THEN
    -- DELETE : 잔고 삭제
    DELETE FROM BOND_BALANCE
     WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- 영업일자(잔고 PK)
       AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- 펀드코드(잔고 PK)
       AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- 종목코드(잔고 PK)
       AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- 매수일자(잔고 PK)
       AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- 매수단가(잔고 PK)
       AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
  ELSIF I_CANCEL_INFO.EVENT_TYPE = '2' THEN
    -- * 매도전 잔고로 복구
    
    -- 잔고수량 RULE //
    IF T_ORGN_BOND_TRADE.STT_TERM_SECT = '1' THEN
      T_BOND_BALANCE.TOT_QTY       := T_BOND_BALANCE.TOT_QTY + T_ORGN_BOND_TRADE.TRD_QTY;                                             -- 총잔고수량
      T_BOND_BALANCE.TDY_AVAL_QTY  := T_BOND_BALANCE.TDY_AVAL_QTY + T_ORGN_BOND_TRADE.TRD_QTY;                                        -- 당일가용수량
      T_BOND_BALANCE.NDY_AVAL_QTY  := T_BOND_BALANCE.NDY_AVAL_QTY + T_ORGN_BOND_TRADE.TRD_QTY;                                        -- 익일가용수량
    ELSIF T_ORGN_BOND_TRADE.STT_TERM_SECT = '2' THEN
      T_BOND_BALANCE.TOT_QTY       := T_BOND_BALANCE.TOT_QTY + T_ORGN_BOND_TRADE.TRD_QTY;                                             -- 총잔고수량
      T_BOND_BALANCE.TDY_AVAL_QTY  := T_BOND_BALANCE.TDY_AVAL_QTY;                                                                    -- 당일가용수량
      T_BOND_BALANCE.NDY_AVAL_QTY  := T_BOND_BALANCE.NDY_AVAL_QTY + T_ORGN_BOND_TRADE.TRD_QTY;                                        -- 익일가용수량
    END IF;
    -- // END
    
    T_BOND_BALANCE.BOOK_AMT        := (T_BOND_BALANCE.BOOK_AMT - T_ORGN_BOND_TRADE.SANGGAK_AMT) + T_ORGN_BOND_TRADE.BOOK_AMT;         -- 장부금액
    T_BOND_BALANCE.BOOK_PRC_AMT    := (T_BOND_BALANCE.BOOK_PRC_AMT - T_ORGN_BOND_TRADE.SANGGAK_AMT) + T_ORGN_BOND_TRADE.BOOK_PRC_AMT; -- 장부원가
    T_BOND_BALANCE.ACCRUED_INT     := T_BOND_BALANCE.ACCRUED_INT + T_ORGN_BOND_TRADE.ACCRUED_INT;                                     -- 경과이자
    T_BOND_BALANCE.BTRM_UNPAID_INT := T_BOND_BALANCE.BTRM_UNPAID_INT + T_ORGN_BOND_TRADE.BTRM_UNPAID_INT;                             -- 전기미수이자
    T_BOND_BALANCE.TTRM_BOND_INT   := T_BOND_BALANCE.TTRM_BOND_INT + T_ORGN_BOND_TRADE.BTRM_UNPAID_INT;                               -- 당기채권이자
    T_BOND_BALANCE.SANGGAK_AMT     := T_BOND_BALANCE.SANGGAK_AMT - T_ORGN_BOND_TRADE.SANGGAK_AMT;                                     -- 상각금액
    T_BOND_BALANCE.MI_SANGGAK_AMT  := T_BOND_BALANCE.MI_SANGGAK_AMT + T_BOND_BALANCE.SANGGAK_AMT;                                     -- 미상각금액(잔고.미상각금액-상각금액)
    T_BOND_BALANCE.TRD_PRFT        := T_BOND_BALANCE.TRD_PRFT - T_ORGN_BOND_TRADE.TRD_PRFT;                                           -- 매매이익
    T_BOND_BALANCE.TRD_LOSS        := T_BOND_BALANCE.TRD_LOSS - T_ORGN_BOND_TRADE.TRD_LOSS;                                           -- 매매손실
    T_BOND_BALANCE.TXSTD_AMT       := T_BOND_BALANCE.TXSTD_AMT - T_ORGN_BOND_TRADE.TXSTD_AMT;                                         -- 과표금액
    T_BOND_BALANCE.CORP_TAX        := T_BOND_BALANCE.CORP_TAX - T_ORGN_BOND_TRADE.CORP_TAX;                                           -- 선급법인세
    T_BOND_BALANCE.UNPAID_CORP_TAX := T_BOND_BALANCE.UNPAID_CORP_TAX - T_ORGN_BOND_TRADE.UNPAID_CORP_TAX;                             -- 미지급법인세
    
    -- UPDATE : 잔고 복구
    UPDATE BOND_BALANCE 
       SET ROW = T_BOND_BALANCE
     WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- 영업일자(잔고 PK)
       AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- 펀드코드(잔고 PK)
       AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- 종목코드(잔고 PK)
       AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- 매수일자(잔고 PK)
       AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- 매수단가(잔고 PK)
       AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 6)원거래내역 취소처리
  --   * 취소여부 필드값 세팅
  ----------------------------------------------------------------------------------------------------
  
  
  -- UPDATE : 취소처리
  UPDATE BOND_TRADE 
     SET ROW = T_ORGN_BOND_TRADE
   WHERE TRD_DATE = T_ORGN_BOND_TRADE.TRD_DATE -- 거래일자(거래내역 PK)
     AND TRD_SEQ  = T_ORGN_BOND_TRADE.TRD_SEQ; -- 거래일련번호(거래내역 PK)
  
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 7)취소거래내역 등록
  ----------------------------------------------------------------------------------------------------
  O_BOND_TRADE.TRD_DATE   := I_CANCEL_INFO.TRD_DATE;    -- 거래일자(PK)
  
  -- 거래일련번호 채번 RULE //
  SELECT NVL(MAX(TRD_SEQ), 0) + 1 AS TRD_SEQ
    INTO O_BOND_TRADE.TRD_SEQ                           -- 거래일련번호(PK)
    FROM BOND_TRADE
   WHERE TRD_DATE = I_SELL_INFO.TRD_DATE;
  -- // END
  
  O_BOND_TRADE.FUND_CODE  := T_BOND_BALANCE.FUND_CODE;  -- 펀드코드
  O_BOND_TRADE.BOND_CODE  := T_BOND_BALANCE.BOND_CODE;  -- 종목코드
  O_BOND_TRADE.BUY_DATE   := T_BOND_BALANCE.TRD_DATE;   -- 매수일자
  O_BOND_TRADE.BUY_PRICE  := T_BOND_BALANCE.BUY_PRICE;  -- 매수단가
  O_BOND_TRADE.BALAN_SEQ  := T_BOND_BALANCE.BALAN_SEQ;  -- 잔고일련번호
  
  O_BOND_TRADE.EVENT_DATE := T_EVENT_RESULT.EVENT_DATE; -- 이벤트일
  O_BOND_TRADE.EVENT_SEQ  := T_EVENT_RESULT.EVENT_SEQ;  -- 이벤트 SEQ
  
  
  -- INSERT : 거래내역 등록
  INSERT INTO BOND_TRADE VALUES O_BOND_TRADE;
  
  
  
  DBMS_OUTPUT.PUT_LINE('PR_CANCEL_BOND END');
  
END;