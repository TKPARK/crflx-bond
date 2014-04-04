CREATE OR REPLACE PROCEDURE ISS.PR_SELL_BOND (
  I_SELL_INFO  IN  SELL_INFO_TYPE_S               -- TYPE    : 매도정보
, O_BOND_TRADE OUT BOND_TRADE%ROWTYPE             -- ROWTYPE : 거래내역
) IS
  --
  T_EVENT_INFO     EVENT_INFO_TYPE;               -- TYPE    : 매도이벤트 INPUT
  T_EVENT_RESULT   EVENT_RESULT_NESTED_S%ROWTYPE; -- ROWTYPE : 매수이벤트 OUTPUT
  T_BOND_BALANCE   BOND_BALANCE%ROWTYPE;          -- ROWTYPE : 잔고
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)잔고확인
  --   * 잔고TABLE을 조회하여 잔고 유무 확인
  ----------------------------------------------------------------------------------------------------
  FOR C1 IN (SELECT *
               FROM BOND_BALANCE
              WHERE BIZ_DATE  = I_SELL_INFO.BIZ_DATE   -- 영업일자(잔고 PK)
                AND FUND_CODE = I_SELL_INFO.FUND_CODE  -- 펀드코드(잔고 PK)
                AND BOND_CODE = I_SELL_INFO.BOND_CODE  -- 종목코드(잔고 PK)
                AND BUY_DATE  = I_SELL_INFO.BUY_DATE   -- 매수일자(잔고 PK)
                AND BUY_PRICE = I_SELL_INFO.BUY_PRICE  -- 매수단가(잔고 PK)
                AND BALAN_SEQ = I_SELL_INFO.BALAN_SEQ) -- 잔고일련번호(잔고 PK)
  LOOP
    T_BOND_BALANCE := C1;
    EXIT;
  END LOOP;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)입력값 검증(INPUT 필드)
  --   SELL_DATE  -- 매도일자
  --   SELL_PRICE -- 매도단가
  --   SELL_QTY   -- 매도수량
  ----------------------------------------------------------------------------------------------------
  -- 매도일자
  IF I_SELL_INFO.SELL_DATE = '' THEN
    PCZ_RAISE(-20999, '매도일자 오류');
  END IF;
  -- 매도단가
  IF I_SELL_INFO.SELL_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '매도단가 오류');
  END IF;
  -- 매도수량
  IF I_SELL_INFO.SELL_QTY <= 0 THEN
    PCZ_RAISE(-20999, '매도수량 오류');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3)변수초기화
  --   * Object들을 초기화 및 Default값으로 설정함
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO   := FN_INIT_EVENT_INFO();
  T_EVENT_RESULT := FN_INIT_EVENT_RESULT();
  O_BOND_TRADE   := FN_INIT_BOND_TRADE();
  
  -- 결제일자 RULE
  -- 1.당일 : 결제일자 = 매도일자
  -- 2.익일 : 결제일자 = 매도일자 + 1일
  IF I_SELL_INFO.STT_TERM_SECT = '1' THEN
    O_BOND_TRADE.SETL_DATE    := I_SELL_INFO.SELL_DATE;
  ELSIF I_SELL_INFO.STT_TERM_SECT = '2' THEN
    O_BOND_TRADE.SETL_DATE    := TO_CHAR(TO_DATE(I_SELL_INFO.SELL_DATE, 'YYYYMMDD')+1), 'YYYYMMDD');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)매도 이벤트 처리 프로시져 호출
  --   * INPUT 설정
  --   * 상각금액산출, 상각표 재산출, 상각이자, 장부금액산출
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := T_BOND_BALANCE.FUND_CODE; -- 펀드코드(채권잔고의PK)
  T_EVENT_INFO.BOND_CODE  := T_BOND_BALANCE.BOND_CODE; -- 종목코드(채권잔고의PK)
  T_EVENT_INFO.BUY_DATE   := T_BOND_BALANCE.TRD_DATE;  -- 매수일자(채권잔고의PK)
  T_EVENT_INFO.BUY_PRICE  := T_BOND_BALANCE.BUY_PRICE; -- 매수단가(채권잔고의PK)
  T_EVENT_INFO.BALAN_SEQ  := T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(채권잔고의PK)
  T_EVENT_INFO.EVENT_DATE := O_BOND_TRADE.SETL_DATE;   -- 이벤트일
  T_EVENT_INFO.EVENT_TYPE := I_SELL_INFO.EVENT_TYPE;   -- Event종류(1.매수,2.매도,3.금리변동,4.손상,5.회복)
  T_EVENT_INFO.DL_UV      := I_SELL_INFO.BUY_PRICE;    -- 거래단가
  T_EVENT_INFO.DL_QT      := I_SELL_INFO.BUY_QTY;      -- 거래수량
  T_EVENT_INFO.STL_DT_TP  := I_SELL_INFO.STL_DT_TP;    -- 결제일구분(1.당일,2.익일)
  T_EVENT_INFO.SELL_RT    := ;                         -- 매도율
  
  PKG_EIR_NESTED_NSC.PR_APPLY_ADD_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5)거래내역 등록(기준정보 계산)
  --   * T_EVENT_RESULT 데이터를 가지고 기준정보 설정
  --   * 기준정보에 필요한 조회 및 계산 로직 등을 구현
  ----------------------------------------------------------------------------------------------------
  
  -- 매도 기준정보
  I_BOND_TRADE.BOND_EIR        := T_EVENT_RESULT.EIR;                                        -- 유효이자율
  I_BOND_TRADE.TOT_DCNT        := ISS.FN_CALC_DAYS();                                        -- 총일수
  I_BOND_TRADE.SRV_DCNT        := ISS.FN_CALC_DAYS();                                        -- 잔존일수
  I_BOND_TRADE.LPCNT           := ISS.FN_CALC_DAYS();                                        -- 경과일수
  I_BOND_TRADE.HOLD_DCNT       := ISS.FN_CALC_DAYS();                                        -- 보유일수
  I_BOND_TRADE.EXPR_DATE       := ;                                                          -- 만기일자
  
  I_BOND_TRADE.TOT_INT         := T_EVENT_RESULT.ACCRUED_INT;                                -- 총이자금액
  I_BOND_TRADE.ACCRUED_INT     := T_EVENT_RESULT.ACCRUED_INT;                                -- 경과이자
  I_BOND_TRADE.BTRM_UNPAID_INT := ;                                                          -- 전기미수이자
  I_BOND_TRADE.TTRM_BOND_INT   := ;                                                          -- 당기채권이자
  
  I_BOND_TRADE.TRD_FACE_AMT    := I_BOND_TRADE.TRD_QTY * 1000;                               -- 매매액면(수량 * 1000)
  I_BOND_TRADE.TRD_AMT         := TRUNC(I_BOND_TRADE.TRD_PRICE * I_BOND_TRADE.TRD_QTY / 10); -- 매매금액(수량 * 단가 / 10)
  I_BOND_TRADE.TRD_NET_AMT     := I_BOND_TRADE.TRD_AMT-I_BOND_TRADE.ACCRUED_INT;             -- 매매정산금액(매매금액 - 경과이자)
  I_BOND_TRADE.SANGGAK_AMT     := ;                                                          -- 상각금액
  I_BOND_TRADE.BOOK_AMT        := I_BOND_TRADE.TRD_NET_AMT;                                  -- 장부금액
  I_BOND_TRADE.BOOK_PRC_AMT    := I_BOND_TRADE.TRD_NET_AMT;                                  -- 장부원가
  I_BOND_TRADE.TRD_PRFT        := ;                                                          -- 매매이익
  I_BOND_TRADE.TRD_LOSS        := ;                                                          -- 매매손익
  I_BOND_TRADE.BTRM_EVAL_PRFT  := ;                                                          -- 전기미실현평가이익
  I_BOND_TRADE.BTRM_EVAL_LOSS  := ;                                                          -- 전기미실현평가손익
  I_BOND_TRADE.TXSTD_AMT       := ;                                                          -- 과표금액
  I_BOND_TRADE.CORP_TAX        := ;                                                          -- 선급법인세
  I_BOND_TRADE.UNPAID_CORP_TAX := ;                                                          -- 미지급법인세
  
  INSERT INTO BOND_TRADE VALUES I_BOND_TRADE;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 6)잔고 업데이트
  ----------------------------------------------------------------------------------------------------
  UPDATE BOND_BALANCE 
     SET ROW = T_BOND_BALANCE
   WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- 영업일자(잔고 PK)
     AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- 펀드코드(잔고 PK)
     AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- 종목코드(잔고 PK)
     AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- 매수일자(잔고 PK)
     AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- 매수단가(잔고 PK)
     AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
  
  
  
  
  DBMS_OUTPUT.PUT_LINE('PR_SELL_BOND END');
  
END;