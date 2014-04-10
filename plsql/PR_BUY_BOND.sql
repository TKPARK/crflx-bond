CREATE OR REPLACE PROCEDURE ISS.PR_BUY_BOND (
  I_BUY_INFO   IN  BUY_INFO_TYPE_S                   -- TYPE    : 매수정보
, O_BOND_TRADE OUT BOND_TRADE%ROWTYPE                -- ROWTYPE : 거래내역
) IS
  -- CURSOR : 종목
  CURSOR C_BOND_INFO_CUR IS
    SELECT *
      FROM BOND_INFO
     WHERE BOND_CODE = I_BUY_INFO.BOND_CODE;
  -- TYPE
  T_EVENT_INFO   PKG_EIR_NESTED_NSC.EVENT_INFO_TYPE; -- TYPE    : 이벤트 INPUT
  T_EVENT_RESULT EVENT_RESULT_NESTED_S%ROWTYPE;      -- ROWTYPE : 이벤트 OUTPUT
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;               -- ROWTYPE : 잔고
  T_BOND_INFO    BOND_INFO%ROWTYPE;                  -- ROWTYPE : 종목
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)입력값 검증(INPUT 필드)
  --   TRD_DATE   -- 거래일자
  --   FUND_CODE  -- 펀드코드
  --   BOND_CODE  -- 종목코드
  --   BUY_PRICE  -- 매수단가
  --   BUY_QTY    -- 매수수량
  --   BOND_IR    -- 표면이자율
  --   STL_DT_TP  -- 결제일구분(1.당일, 2.익일)
  ----------------------------------------------------------------------------------------------------
  -- 매수단가
  IF I_BUY_INFO.BUY_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '매수단가 오류');
  END IF;
  -- 매수수량
  IF I_BUY_INFO.BUY_QTY <= 0 THEN
    PCZ_RAISE(-20999, '매수수량 오류');
  END IF;
  -- 표면이자율
  IF I_BUY_INFO.BOND_IR <= 0 THEN
    PCZ_RAISE(-20999, '표면이자율 오류');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)종목 확인
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_INFO_CUR;
  FETCH C_BOND_INFO_CUR INTO T_BOND_INFO;
  IF C_BOND_INFO_CUR%NOTFOUND THEN
    CLOSE C_BOND_INFO_CUR;
    RAISE_APPLICATION_ERROR(-20011, '종목 오류');
  END IF;
  CLOSE C_BOND_INFO_CUR;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3)변수초기화
  --   * Object들을 초기화 및 Default값으로 설정함
  --   * 잔고 TABLE SEQ 채번
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO   := PKG_EIR_NESTED_NSC.FN_INIT_EVENT_INFO();
  T_EVENT_RESULT := FN_INIT_EVENT_RESULT();
  O_BOND_TRADE   := FN_INIT_BOND_TRADE();
  T_BOND_BALANCE := FN_INIT_BOND_BALANCE();
  T_BOND_INFO    := FN_INIT_BOND_INFO();  
  
  -- 잔고일련번호 채번
  SELECT NVL(MAX(BALAN_SEQ), 0) + 1 AS BALAN_SEQ
    INTO O_BOND_TRADE.BALAN_SEQ
    FROM BOND_BALANCE
   WHERE BIZ_DATE  = I_BUY_INFO.TRD_DATE
     AND FUND_CODE = I_BUY_INFO.FUND_CODE
     AND BOND_CODE = I_BUY_INFO.BOND_CODE
     AND BUY_DATE  = I_BUY_INFO.TRD_DATE
     AND BUY_PRICE = I_BUY_INFO.BUY_PRICE;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)매수 처리 프로시져 호출
  --   * INPUT 설정
  --   * 경과이자, 현금흐름 생성, EIR산출, 상각표 생성 처리
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := I_BUY_INFO.FUND_CODE;   -- 펀드코드(잔고 PK)
  T_EVENT_INFO.BOND_CODE  := I_BUY_INFO.BOND_CODE;   -- 종목코드(잔고 PK)
  T_EVENT_INFO.BUY_DATE   := I_BUY_INFO.TRD_DATE;    -- 매수일자(잔고 PK)
  T_EVENT_INFO.BUY_PRICE  := I_BUY_INFO.BUY_PRICE;   -- 매수단가(잔고 PK)
  T_EVENT_INFO.BALAN_SEQ  := O_BOND_TRADE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
  T_EVENT_INFO.EVENT_DATE := I_BUY_INFO.TRD_DATE;    -- 이벤트일
  T_EVENT_INFO.EVENT_TYPE := '1';                    -- Event종류(1.매수,2.매도,3.금리변동,4.손상,5.회복)
  T_EVENT_INFO.DL_UV      := I_BUY_INFO.BUY_PRICE;   -- 거래단가
  T_EVENT_INFO.DL_QT      := I_BUY_INFO.BUY_QTY;     -- 거래수량
  T_EVENT_INFO.STL_DT_TP  := I_BUY_INFO.STL_DT_TP;   -- 결제일구분(1.당일,2.익일)
  T_EVENT_INFO.IR         := I_BUY_INFO.BOND_IR;     -- 표면이자율
  
  --PKG_EIR_NESTED_NSC.PR_NEW_BUY_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5)거래내역 등록(기준정보 계산)
  --   * T_EVENT_RESULT 데이터를 가지고 기준정보 설정
  --   * 기준정보에 필요한 조회 및 계산 로직 등을 구현
  ----------------------------------------------------------------------------------------------------
  O_BOND_TRADE.TRD_DATE            := I_BUY_INFO.TRD_DATE;                                   -- 거래일자(PK)
  
  -- 거래일련번호 채번 RULE //
  SELECT NVL(MAX(TRD_SEQ), 0) + 1 AS TRD_SEQ
    INTO O_BOND_TRADE.TRD_SEQ                                                                -- 거래일련번호(PK)
    FROM BOND_TRADE
   WHERE TRD_DATE = I_BUY_INFO.TRD_DATE;
  -- // END
  
  O_BOND_TRADE.FUND_CODE           := I_BUY_INFO.FUND_CODE;                                  -- 펀드코드
  O_BOND_TRADE.BOND_CODE           := I_BUY_INFO.BOND_CODE;                                  -- 종목코드
  O_BOND_TRADE.BUY_DATE            := I_BUY_INFO.TRD_DATE;                                   -- 매수일자
  O_BOND_TRADE.BUY_PRICE           := I_BUY_INFO.BUY_PRICE;                                  -- 매수단가
  O_BOND_TRADE.TRD_TYPE_CD         := '2';                                                   -- 매매유형코드(1.인수,2.직매수,3.직매도,4.상환)
  O_BOND_TRADE.GOODS_BUY_SELL_SECT := '1';                                                   -- 상품매수매도구분(1.상품매수,2.상품매도)
  O_BOND_TRADE.STT_TERM_SECT       := I_BUY_INFO.STL_DT_TP;                                  -- 결제기간구분(0.당일,1.익일)
  
  -- 결제일자 RULE //
  -- 1.당일 : 결제일자 = 매수일자
  -- 2.익일 : 결제일자 = 영업일 계산 모듈로 처리
  IF I_BUY_INFO.STL_DT_TP = '1' THEN
    O_BOND_TRADE.SETL_DATE := I_BUY_INFO.TRD_DATE;
  ELSIF I_BUY_INFO.STL_DT_TP = '2' THEN
    -- 영업일 계산 모듈로 처리
    O_BOND_TRADE.SETL_DATE := TO_CHAR(TO_DATE(I_BUY_INFO.TRD_DATE, 'YYYYMMDD')+1), 'YYYYMMDD');
  END IF;
  -- // END
  
  O_BOND_TRADE.EXPR_DATE           := T_BOND_INFO.EXPIRE_DATE;                               -- 만기일자
  O_BOND_TRADE.EVENT_DATE          := T_EVENT_RESULT.EVENT_DATE;                             -- 이벤트일
  O_BOND_TRADE.EVENT_SEQ           := T_EVENT_RESULT.EVENT_SEQ;                              -- 이벤트 SEQ
  O_BOND_TRADE.TRD_PRICE           := I_BUY_INFO.BUY_PRICE;                                  -- 매매단가
  O_BOND_TRADE.TRD_QTY             := I_BUY_INFO.BUY_QTY;                                    -- 매매수량
  O_BOND_TRADE.BOND_EIR            := T_EVENT_RESULT.EIR;                                    -- 유효이자율
  O_BOND_TRADE.BOND_IR             := I_BUY_INFO.BOND_IR;                                    -- 표면이자율
  O_BOND_TRADE.TOT_INT             := T_EVENT_RESULT.ACCRUED_INT;                            -- 총이자금액(매수시점이므로 총이자는 경과이자)
  O_BOND_TRADE.ACCRUED_INT         := T_EVENT_RESULT.ACCRUED_INT;                            -- 경과이자
  O_BOND_TRADE.TRD_FACE_AMT        := I_BUY_INFO.BUY_QTY * 1000;                             -- 매매액면(수량 * 1000)
  O_BOND_TRADE.TRD_AMT             := TRUNC(I_BUY_INFO.BUY_PRICE * I_BUY_INFO.BUY_QTY / 10); -- 매매금액(수량 * 단가 / 10)
  O_BOND_TRADE.TRD_NET_AMT         := O_BOND_TRADE.TRD_AMT - T_EVENT_RESULT.ACCRUED_INT;     -- 매매정산금액(매매금액 - 경과이자)
  O_BOND_TRADE.BOOK_AMT            := O_BOND_TRADE.TRD_NET_AMT;                              -- 장부금액
  O_BOND_TRADE.BOOK_PRC_AMT        := O_BOND_TRADE.TRD_NET_AMT;                              -- 장부원가
  
  -- INSERT : 거래내역 등록
  INSERT INTO BOND_TRADE VALUES O_BOND_TRADE;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 6)잔고 등록
  ----------------------------------------------------------------------------------------------------
  T_BOND_BALANCE.BIZ_DATE       := O_BOND_TRADE.TRD_DATE;         -- 영업일자(PK)
  T_BOND_BALANCE.FUND_CODE      := O_BOND_TRADE.FUND_CODE;        -- 펀드코드(PK)
  T_BOND_BALANCE.BOND_CODE      := O_BOND_TRADE.BOND_CODE;        -- 종목코드(PK)
  T_BOND_BALANCE.BUY_DATE       := O_BOND_TRADE.BUY_DATE;         -- 매수일자(PK)
  T_BOND_BALANCE.BUY_PRICE      := O_BOND_TRADE.BUY_PRICE;        -- 매수단가(PK)
  T_BOND_BALANCE.BALAN_SEQ      := O_BOND_TRADE.BALAN_SEQ;        -- 잔고일련번호(PK)
  T_BOND_BALANCE.BOND_IR        := O_BOND_TRADE.BOND_IR;          -- IR
  T_BOND_BALANCE.BOND_EIR       := O_BOND_TRADE.BOND_EIR;         -- EIR
  
  -- 잔고수량 RULE //
  -- 1.당일(매수 100)
  --   ex)총잔고수량 = 100, 당일잔고수량 = 100, 익일잔고수량 = 100;
  -- 2.익일(매수 100)
  --   ex)총잔고수량 = 100, 당일잔고수량 =   0, 익일잔고수량 = 100;
  IF O_BOND_TRADE.STT_TERM_SECT = '1' THEN
    T_BOND_BALANCE.TOT_QTY        := O_BOND_TRADE.TRD_QTY;        -- 총잔고수량
    T_BOND_BALANCE.TDY_AVAL_QTY   := O_BOND_TRADE.TRD_QTY;        -- 당일가용수량
    T_BOND_BALANCE.NDY_AVAL_QTY   := O_BOND_TRADE.TRD_QTY;        -- 익일가용수량
  ELSIF O_BOND_TRADE.STT_TERM_SECT = '2' THEN
    T_BOND_BALANCE.TOT_QTY        := O_BOND_TRADE.TRD_QTY;        -- 총잔고수량
    T_BOND_BALANCE.TDY_AVAL_QTY   := 0;                           -- 당일가용수량
    T_BOND_BALANCE.NDY_AVAL_QTY   := O_BOND_TRADE.TRD_QTY;        -- 익일가용수량
  END IF;
  -- // END
  
  T_BOND_BALANCE.BOOK_AMT       := O_BOND_TRADE.BOOK_AMT;         -- 장부금액
  T_BOND_BALANCE.BOOK_PRC_AMT   := O_BOND_TRADE.BOOK_PRC_AMT;     -- 장부원가
  T_BOND_BALANCE.ACCRUED_INT    := O_BOND_TRADE.ACCRUED_INT;      -- 경과이자
  T_BOND_BALANCE.MI_SANGGAK_AMT := T_EVENT_RESULT.MI_SANGGAK_AMT; -- 미상각금액(미상각이자)
  T_BOND_BALANCE.DRT_BUY_QTY    := O_BOND_TRADE.TRD_QTY;          -- 직매수수량
  
  -- INSERT : 잔고 등록
  INSERT INTO BOND_BALANCE VALUES T_BOND_BALANCE;
  
  
  
  DBMS_OUTPUT.PUT_LINE('PR_BUY_BOND END');
  
END;