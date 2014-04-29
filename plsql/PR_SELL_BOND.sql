CREATE OR REPLACE PROCEDURE ISS.PR_SELL_BOND (
  I_SELL_INFO  IN  SELL_INFO_TYPE                 -- TYPE    : 매도정보
, O_BOND_TRADE OUT BOND_TRADE%ROWTYPE             -- ROWTYPE : 거래내역
) IS
  -- TYPE
  T_EVENT_INFO     EVENT_INFO_TYPE;               -- TYPE    : 이벤트 INPUT
  T_EVENT_RESULT   EVENT_RESULT_EIR%ROWTYPE;      -- ROWTYPE : 이벤트 OUTPUT
  T_BOND_BALANCE   BOND_BALANCE%ROWTYPE;          -- ROWTYPE : 잔고
  T_BOND_INFO      BOND_INFO%ROWTYPE;             -- ROWTYPE : 종목
  
  -- 기준정보 필드
  T_BF_INT_DATE    CHAR(8) := '';-- 직전이자지급일
  T_TOT_INT_DAYS   NUMBER  := 0; -- 총이자일수
  T_TRD_PR_LO      NUMBER  := 0; -- 매매손익
  
  -- CURSOR : 종목
  CURSOR C_BOND_INFO_CUR IS
    SELECT *
      FROM BOND_INFO
     WHERE BOND_CODE = I_SELL_INFO.BOND_CODE;
  -- CURSOR : 잔고
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_SELL_INFO.TRD_DATE   -- 거래일자(잔고 PK)
       AND FUND_CODE = I_SELL_INFO.FUND_CODE  -- 펀드코드(잔고 PK)
       AND BOND_CODE = I_SELL_INFO.BOND_CODE  -- 종목코드(잔고 PK)
       AND BUY_DATE  = I_SELL_INFO.BUY_DATE   -- 매수일자(잔고 PK)
       AND BUY_PRICE = I_SELL_INFO.BUY_PRICE  -- 매수단가(잔고 PK)
       AND BALAN_SEQ = I_SELL_INFO.BALAN_SEQ  -- 잔고일련번호(잔고 PK)
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
  --   SELL_PRICE -- 매도단가
  --   SELL_QTY   -- 매도수량
  --   STL_DT_TP  -- 결제일구분(1.당일, 2.익일)
  ----------------------------------------------------------------------------------------------------
  -- 매도단가
  IF I_SELL_INFO.SELL_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '매도단가 오류');
  END IF;
  -- 매도수량
  IF I_SELL_INFO.SELL_QTY <= 0 THEN
    PCZ_RAISE(-20999, '매도수량 오류');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)종목 및 잔고 확인
  --   * 종목 유무 확인
  --   * 잔고 유무 확인
  --   * 결제일구분에 따른 당일, 익일 가용수량 확인
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_INFO_CUR;
    FETCH C_BOND_INFO_CUR INTO T_BOND_INFO;
    IF C_BOND_INFO_CUR%NOTFOUND THEN
      CLOSE C_BOND_INFO_CUR;
      RAISE_APPLICATION_ERROR(-20011, '종목 오류');
    END IF;
  CLOSE C_BOND_INFO_CUR;
  
  OPEN C_BOND_BALANCE_CUR;
    FETCH C_BOND_BALANCE_CUR INTO T_BOND_BALANCE;
    IF C_BOND_BALANCE_CUR%NOTFOUND THEN
      CLOSE C_BOND_BALANCE_CUR;
      RAISE_APPLICATION_ERROR(-20011, '잔고 오류');
    END IF;
  CLOSE C_BOND_BALANCE_CUR;
  
  IF I_SELL_INFO.STL_DT_TP = '1' THEN
    IF I_SELL_INFO.SELL_QTY > T_BOND_BALANCE.TDY_AVAL_QTY THEN
      RAISE_APPLICATION_ERROR(-20011, '당일가용수량 오류');
    END IF;
  ELSIF I_SELL_INFO.STL_DT_TP = '2' THEN
    IF I_SELL_INFO.SELL_QTY > T_BOND_BALANCE.NDY_AVAL_QTY THEN
      RAISE_APPLICATION_ERROR(-20011, '익일가용수량 오류');
    END IF;
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3)변수초기화
  --   * Object들을 초기화 및 Default값으로 설정함
  ----------------------------------------------------------------------------------------------------
  PKG_EIR_NESTED_NSC.PR_EVENT_INFO_TYPE_INIT(T_EVENT_INFO);
  PR_INIT_BOND_TRADE(O_BOND_TRADE);
  
  -- 결제일자 RULE //
  -- 1.당일 : 결제일자 = 매도일자
  -- 2.익일 : 결제일자 = 영업일 계산 모듈로 처리
  IF I_SELL_INFO.STL_DT_TP = '1' THEN
    O_BOND_TRADE.SETL_DATE := I_SELL_INFO.TRD_DATE;
  ELSIF I_SELL_INFO.STL_DT_TP = '2' THEN
    -- 영업일 계산 모듈로 처리
    O_BOND_TRADE.SETL_DATE := TO_CHAR(TO_DATE(I_SELL_INFO.TRD_DATE, 'YYYYMMDD')+1, 'YYYYMMDD');
  END IF;
  -- // END
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)매도 처리 프로시져 호출
  --   * INPUT 설정
  --   * 상각금액산출, 상각표 재산출, 상각이자, 장부금액산출
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE           := T_BOND_BALANCE.FUND_CODE;                      -- 펀드코드(잔고 PK)
  T_EVENT_INFO.BOND_CODE           := T_BOND_BALANCE.BOND_CODE;                      -- 종목코드(잔고 PK)
  T_EVENT_INFO.BUY_DATE            := T_BOND_BALANCE.BUY_DATE;                       -- 매수일자(잔고 PK)
  T_EVENT_INFO.BUY_PRICE           := T_BOND_BALANCE.BUY_PRICE;                      -- 매수단가(잔고 PK)
  T_EVENT_INFO.BALAN_SEQ           := T_BOND_BALANCE.BALAN_SEQ;                      -- 잔고일련번호(잔고 PK)
  T_EVENT_INFO.EVENT_DATE          := O_BOND_TRADE.SETL_DATE;                        -- 이벤트일
  T_EVENT_INFO.EVENT_TYPE          := '2';                                           -- Event종류(1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복)
  T_EVENT_INFO.DL_UV               := I_SELL_INFO.SELL_PRICE;                        -- 거래단가
  T_EVENT_INFO.DL_QT               := I_SELL_INFO.SELL_QTY;                          -- 거래수량
  T_EVENT_INFO.IR                  := I_SELL_INFO.BOND_IR;                           -- 표면이자율
  T_EVENT_INFO.SELL_RT             := I_SELL_INFO.SELL_QTY / T_BOND_BALANCE.TOT_QTY; -- 매도율
  
  PKG_EIR_NESTED_NSC.PR_APPLY_ADD_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5)거래내역 등록(기준정보 계산)
  --   * T_EVENT_RESULT 데이터를 가지고 기준정보 설정
  --   * 기준정보에 필요한 조회 및 계산 로직 등을 구현
  ----------------------------------------------------------------------------------------------------
  O_BOND_TRADE.TRD_DATE            := I_SELL_INFO.TRD_DATE;                          -- 거래일자(PK)
  
  -- 거래일련번호 채번 RULE //
  SELECT NVL(MAX(TRD_SEQ), 0) + 1 AS TRD_SEQ
    INTO O_BOND_TRADE.TRD_SEQ                                                        -- 거래일련번호(PK)
    FROM BOND_TRADE
   WHERE TRD_DATE = I_SELL_INFO.TRD_DATE;
  -- // END
  
  O_BOND_TRADE.FUND_CODE           := T_BOND_BALANCE.FUND_CODE;                      -- 펀드코드
  O_BOND_TRADE.BOND_CODE           := T_BOND_BALANCE.BOND_CODE;                      -- 종목코드
  O_BOND_TRADE.BUY_DATE            := T_BOND_BALANCE.BUY_DATE;                       -- 매수일자
  O_BOND_TRADE.BUY_PRICE           := T_BOND_BALANCE.BUY_PRICE;                      -- 매수단가
  O_BOND_TRADE.BALAN_SEQ           := T_BOND_BALANCE.BALAN_SEQ;                      -- 잔고일련번호
  O_BOND_TRADE.TRD_TYPE_CD         := '3';                                           -- 매매유형코드(1.인수, 2.직매수, 3.직매도, 4.상환)
  O_BOND_TRADE.GOODS_BUY_SELL_SECT := '2';                                           -- 상품매수매도구분(1.상품매수, 2.상품매도)
  O_BOND_TRADE.STT_TERM_SECT       := I_SELL_INFO.STL_DT_TP;                         -- 결제기간구분(0.당일, 1.익일)
  
  
  O_BOND_TRADE.EXPR_DATE   := T_BOND_INFO.EXPIRE_DATE;   -- 만기일자
  O_BOND_TRADE.EVENT_DATE  := T_EVENT_RESULT.EVENT_DATE; -- 이벤트일
  O_BOND_TRADE.EVENT_SEQ   := T_EVENT_RESULT.EVENT_SEQ;  -- 이벤트SEQ
  O_BOND_TRADE.TRD_PRICE   := I_SELL_INFO.SELL_PRICE;    -- 매매단가
  O_BOND_TRADE.TRD_QTY     := I_SELL_INFO.SELL_QTY;      -- 매매수량
  O_BOND_TRADE.BOND_EIR    := T_BOND_BALANCE.BOND_EIR;   -- 유효이자율
  O_BOND_TRADE.BOND_IR     := T_BOND_BALANCE.BOND_IR;    -- 표면이자율
  
  -- 총이자금액 및 경과이자 RULE //
  -- T_EVENT_RESULT에서 계산 후 리턴값으로 세팅함
--  O_BOND_TRADE.TOT_DCNT    := T_EVENT_RESULT.;           -- 총일수(발행일 ~ 기준일)
--  O_BOND_TRADE.SRV_DCNT    := T_EVENT_RESULT.;           -- 잔존일수(기준일 ~ 만기일)
--  O_BOND_TRADE.LPCNT       := T_EVENT_RESULT.;           -- 경과일수(발행일 ~ 취득일)
--  O_BOND_TRADE.HOLD_DCNT   := T_EVENT_RESULT.;           -- 보유일수(취득일 ~ 기준일)
  -- // END
  
  O_BOND_TRADE.TOT_INT      := T_EVENT_RESULT.TOT_INT;                                       -- 총이자금액(매도액면 * 표면이자율 * 이자일수 / 365)
  O_BOND_TRADE.ACCRUED_INT  := FN_AMOUNT(T_BOND_BALANCE.ACCRUED_INT * T_EVENT_INFO.SELL_RT); -- 경과이자(잔고.경과이자 * 매도율)
  
  O_BOND_TRADE.TRD_FACE_AMT := FN_AMOUNT(O_BOND_TRADE.TRD_QTY * 1000);                       -- 매매액면(수량 * 1000)
  O_BOND_TRADE.TRD_AMT      := TRUNC(O_BOND_TRADE.TRD_PRICE * O_BOND_TRADE.TRD_QTY / 10);    -- 매매금액(수량 * 단가 / 10)
  O_BOND_TRADE.TRD_NET_AMT  := FN_AMOUNT(O_BOND_TRADE.TRD_AMT - O_BOND_TRADE.TOT_INT);       -- 매매정산금액(매매금액 - 총이자금액)
  
  -- 할인상각금액, 할증상각금액 RULE //
  IF T_EVENT_RESULT.SANGGAK_AMT > 0 THEN
    O_BOND_TRADE.EX_CHA_SANGGAK_AMT := T_EVENT_RESULT.SANGGAK_AMT;      -- 할증상각금액
  ELSE
    O_BOND_TRADE.DSCT_SANGGAK_AMT   := T_EVENT_RESULT.SANGGAK_AMT * -1; -- 할인상각금액
  END IF;
  -- // END
  
  O_BOND_TRADE.BOOK_AMT        := FN_AMOUNT((T_BOND_BALANCE.BOOK_AMT + T_EVENT_RESULT.SANGGAK_AMT) * T_EVENT_INFO.SELL_RT);     -- 장부금액((잔고.장부금액 + 상각액) * 매도율)
  O_BOND_TRADE.BOOK_PRC_AMT    := FN_AMOUNT((T_BOND_BALANCE.BOOK_PRC_AMT + T_EVENT_RESULT.SANGGAK_AMT) * T_EVENT_INFO.SELL_RT); -- 장부원가((잔고.장부원가 + 상각액) * 매도율)
  
  O_BOND_TRADE.BTRM_UNPAID_INT := FN_AMOUNT(T_BOND_BALANCE.BTRM_UNPAID_INT * T_EVENT_INFO.SELL_RT);                             -- 전기미수이자(잔고.전기미수이자 * 매도율)
  O_BOND_TRADE.TTRM_BOND_INT   := FN_AMOUNT(O_BOND_TRADE.TOT_INT - O_BOND_TRADE.ACCRUED_INT - O_BOND_TRADE.BTRM_UNPAID_INT);    -- 당기채권이자(총이자금액-경과이자차감액 - 전기미수이자차감액)
  
  -- 매매이익, 매매손실 RULE //
  -- 매매손익 := 매매정산금액-장부원금차감액
  -- IF 매매손익 > 0 THEN
  --   매매이익 = 매매손익, 매매손실 = 0;
  -- ELSE
  --   매매이익 =        0, 매매손실 = 매매손익;
  -- END IF;
  T_TRD_PR_LO := O_BOND_TRADE.TRD_AMT-O_BOND_TRADE.BOOK_AMT-O_BOND_TRADE.TOT_INT;
  IF T_TRD_PR_LO > 0 THEN
  O_BOND_TRADE.TRD_PRFT        := T_TRD_PR_LO;                                   -- 매매이익
  O_BOND_TRADE.TRD_LOSS        := 0;                                             -- 매매손실
  ELSE
  O_BOND_TRADE.TRD_PRFT        := 0;                                             -- 매매이익
  O_BOND_TRADE.TRD_LOSS        := T_TRD_PR_LO * -1;                              -- 매매손실
  END IF;
  -- // END
  
  O_BOND_TRADE.TXSTD_AMT       := O_BOND_TRADE.TOT_INT - O_BOND_TRADE.ACCRUED_INT; -- 과표금액(총이자금액 - 경과이자(보유기간 이자))
  -- 세금계산 모듈로 처리
  O_BOND_TRADE.CORP_TAX        := TRUNC(O_BOND_TRADE.TXSTD_AMT * 0.14, -1);        -- 선급법인세
  O_BOND_TRADE.UNPAID_CORP_TAX := TRUNC(O_BOND_TRADE.TXSTD_AMT * 0.14, -1);        -- 미지급법인세
  
  -- INSERT : 거래내역 등록
  INSERT INTO BOND_TRADE VALUES O_BOND_TRADE;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 6)잔고 업데이트
  ----------------------------------------------------------------------------------------------------
  -- 잔고수량 RULE //
  IF I_SELL_INFO.STL_DT_TP = '1' THEN
    T_BOND_BALANCE.TOT_QTY         := T_BOND_BALANCE.TOT_QTY - O_BOND_TRADE.TRD_QTY;               -- 총잔고수량
    T_BOND_BALANCE.TDY_AVAL_QTY    := T_BOND_BALANCE.TDY_AVAL_QTY - O_BOND_TRADE.TRD_QTY;          -- 당일가용수량
    T_BOND_BALANCE.NDY_AVAL_QTY    := T_BOND_BALANCE.NDY_AVAL_QTY - O_BOND_TRADE.TRD_QTY;          -- 익일가용수량
  ELSIF I_SELL_INFO.STL_DT_TP = '2' THEN
    T_BOND_BALANCE.TOT_QTY         := T_BOND_BALANCE.TOT_QTY - O_BOND_TRADE.TRD_QTY;               -- 총잔고수량
    T_BOND_BALANCE.TDY_AVAL_QTY    := T_BOND_BALANCE.TDY_AVAL_QTY;                                 -- 당일가용수량
    T_BOND_BALANCE.NDY_AVAL_QTY    := T_BOND_BALANCE.NDY_AVAL_QTY - O_BOND_TRADE.TRD_QTY;          -- 익일가용수량
  END IF;
  -- // END
  
  T_BOND_BALANCE.BOOK_AMT        := (T_BOND_BALANCE.BOOK_AMT + T_EVENT_RESULT.SANGGAK_AMT) - O_BOND_TRADE.BOOK_AMT;         -- 장부금액
  T_BOND_BALANCE.BOOK_PRC_AMT    := (T_BOND_BALANCE.BOOK_PRC_AMT + T_EVENT_RESULT.SANGGAK_AMT) - O_BOND_TRADE.BOOK_PRC_AMT; -- 장부원가
  T_BOND_BALANCE.ACCRUED_INT     := T_BOND_BALANCE.ACCRUED_INT - O_BOND_TRADE.ACCRUED_INT;         -- 경과이자
  T_BOND_BALANCE.BTRM_UNPAID_INT := T_BOND_BALANCE.BTRM_UNPAID_INT - O_BOND_TRADE.BTRM_UNPAID_INT; -- 전기미수이자
  T_BOND_BALANCE.TTRM_BOND_INT   := T_BOND_BALANCE.TTRM_BOND_INT - O_BOND_TRADE.TTRM_BOND_INT;     -- 당기채권이자
  T_BOND_BALANCE.SANGGAK_AMT     := T_BOND_BALANCE.SANGGAK_AMT + T_EVENT_RESULT.SANGGAK_AMT;       -- 상각금액
  T_BOND_BALANCE.MI_SANGGAK_AMT  := T_BOND_BALANCE.MI_SANGGAK_AMT - T_BOND_BALANCE.SANGGAK_AMT;    -- 미상각금액(잔고.미상각금액-상각금액)
  T_BOND_BALANCE.TRD_PRFT        := T_BOND_BALANCE.TRD_PRFT + O_BOND_TRADE.TRD_PRFT;               -- 매매이익
  T_BOND_BALANCE.TRD_LOSS        := T_BOND_BALANCE.TRD_LOSS + O_BOND_TRADE.TRD_LOSS;               -- 매매손실
  T_BOND_BALANCE.DRT_SELL_QTY    := T_BOND_BALANCE.DRT_SELL_QTY + O_BOND_TRADE.TRD_QTY;            -- 직매도수량
  T_BOND_BALANCE.TXSTD_AMT       := T_BOND_BALANCE.TXSTD_AMT + O_BOND_TRADE.TXSTD_AMT;             -- 과표금액
  T_BOND_BALANCE.CORP_TAX        := T_BOND_BALANCE.CORP_TAX + O_BOND_TRADE.CORP_TAX;               -- 선급법인세
  T_BOND_BALANCE.UNPAID_CORP_TAX := T_BOND_BALANCE.UNPAID_CORP_TAX + O_BOND_TRADE.UNPAID_CORP_TAX; -- 미지급법인세
  
  -- UPDATE : 잔고 업데이트
  UPDATE BOND_BALANCE 
     SET ROW = T_BOND_BALANCE
   WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- 영업일자(잔고 PK)
     AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- 펀드코드(잔고 PK)
     AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- 종목코드(잔고 PK)
     AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- 매수일자(잔고 PK)
     AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- 매수단가(잔고 PK)
     AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('PR_SELL_BOND END');
  
END;