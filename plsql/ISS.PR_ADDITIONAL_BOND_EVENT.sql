CREATE OR REPLACE PROCEDURE ISS.PR_ADDITIONAL_BOND_EVENT (
  -- 거래내역ROWTPYE을 I/O로 사용(서비스 <-> 프로시저)
  I_BOND_TRADE IN OUT BOND_TRADE%ROWTYPE  -- ROWTYPE : 거래내역
) IS
  --
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;    -- ROWTYPE : 매도후 잔고
  T_BF_BOND_BALANCE BOND_BALANCE%ROWTYPE; -- ROWTYPE : 매도전 잔고
  T_EVENT_INFO   EVENT_INFO_TYPE;         -- TYPE : EVENT_INFO_TYPE
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)입력값 검증(INPUT 필드)
  --   TRD_DATE            -- 거래일자(PK)
  --   FUND_CODE           -- 펀드코드
  --   BOND_CODE           -- 종목코드
  --   BUY_DATE            -- 매수일자
  --   BUY_PRICE           -- 매수단가
  --   TRD_TYPE_CD         -- 매매유형코드(1.인수, 2.직매수, 3.직매도, 4.상환)
  --   GOODS_BUY_SELL_SECT -- 상품매수매도구분(1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복)
  --   STT_TERM_SECT       -- 결제기간구분(1.당일, 2.익일)
  --   TRD_PRICE           -- 매매단가
  --   TRD_QTY             -- 매매수량
  --   SELL_RT             -- 매도율
  ----------------------------------------------------------------------------------------------------
  -- 매매단가
  IF I_BOND_TRADE.TRD_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '매매단가 오류');
  END IF;
  -- 매매수량
  IF I_BOND_TRADE.TRD_QTY <= 0 THEN
    PCZ_RAISE(-20999, '매매수량 오류');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)변수초기화
  --   * Object들을 초기화 및 Default값으로 설정함
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO := FN_INIT_EVENT_INFO();
  T_BOND_BALANCE := FN_INIT_BOND_BALANCE();
  
  -- 거래내역 거래일련번호(PK) 채번
  SELECT NVL(MAX(A.TRD_SEQ), 0) + 1 AS TRD_SEQ
    INTO I_BOND_TRADE.TRD_SEQ
    FROM BOND_TRADE A
   WHERE A.TRD_DATE  = I_BOND_TRADE.TRD_DATE;
  
  -- 잔고 잔고일련번호(PK) 채번
  SELECT NVL(MAX(A.BALAN_SEQ), 0) + 1 AS BALAN_SEQ
    INTO I_BOND_TRADE.BALAN_SEQ
    FROM BOND_BALANCE A
   WHERE A.BIZ_DATE  = I_BOND_TRADE.TRD_DATE
     AND A.FUND_CODE = I_BOND_TRADE.FUND_CODE
     AND A.BOND_CODE = I_BOND_TRADE.BOND_CODE
     AND A.BUY_DATE  = I_BOND_TRADE.BUY_DATE
     AND A.BUY_PRICE = I_BOND_TRADE.BUY_PRICE;
  
  -- 결제일자 RULE
  -- 1.당일 : 결제일자 = 매수일자
  -- 2.익일 : 결제일자 = 매수일자 + 1일
  IF I_BOND_TRADE.STT_TERM_SECT = '1' THEN
    I_BOND_TRADE.SETL_DATE    := I_BOND_TRADE.BUY_DATE; -- 결제일자
  ELSIF I_BOND_TRADE.STT_TERM_SECT = '2' THEN
    I_BOND_TRADE.SETL_DATE    := TO_CHAR(TO_DATE(I_BOND_TRADE.BUY_DATE, 'YYYYMMDD')+1), 'YYYYMMDD'); -- 결제일자
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3-1)INPUT 설정
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := I_BOND_TRADE.FUND_CODE;           -- 펀드코드(채권잔고의 PK)
  T_EVENT_INFO.BOND_CODE  := I_BOND_TRADE.BOND_CODE;           -- 종목코드(채권잔고의 PK)
  T_EVENT_INFO.BUY_DATE   := I_BOND_TRADE.BUY_DATE;            -- Buy Date(채권잔고의 PK)
  T_EVENT_INFO.BUY_PRICE  := I_BOND_TRADE.BUY_PRICE;           -- 매수단가(채권잔고의 PK)
  T_EVENT_INFO.BALAN_SEQ  := I_BOND_TRADE.BALAN_SEQ;           -- 잔고일련번호(채권잔고의 PK)
  T_EVENT_INFO.EVENT_DATE := I_BOND_TRADE.SETL_DATE;           -- 이벤트일(PK)
  T_EVENT_INFO.EVENT_TYPE := I_BOND_TRADE.GOODS_BUY_SELL_SECT; -- Event 종류(1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복)
  T_EVENT_INFO.DL_UV      := I_BOND_TRADE.BUY_PRICE;           -- 거래단가
  T_EVENT_INFO.DL_QT      := I_BOND_TRADE.TRD_QTY;             -- 거래수량
  T_EVENT_INFO.STL_DT_TP  := I_BOND_TRADE.STT_TERM_SECT;       -- 결제일구분(1.당일, 2.익일)
  T_EVENT_INFO.SELL_RT    := I_BOND_TRADE.SELL_RT;             -- 매도율
  
  ----------------------------------------------------------------------------------------------------
  -- 3-2)최초 매수 이벤트 처리 프로시져 호출
  --   * 경과이자, 현금흐름 생성, EIR산출, 상각표 생성 처리
  ----------------------------------------------------------------------------------------------------
  PKG_EIR_NESTED_NSC.PR_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)기준정보 계산
  --   * T_EVENT_RESULT 데이터를 가지고 기준정보 설정
  --   * 기준정보에 필요한 조회 및 계산 로직 등을 구현
  ----------------------------------------------------------------------------------------------------
  -- 매도전 잔고 조회
  SELECT *
    INTO T_BF_BOND_BALANCE
    FROM BOND_BALANCE
   WHERE A.BIZ_DATE  = I_BOND_TRADE.TRD_DATE
     AND A.FUND_CODE = I_BOND_TRADE.FUND_CODE
     AND A.BOND_CODE = I_BOND_TRADE.BOND_CODE
     AND A.BUY_DATE  = I_BOND_TRADE.BUY_DATE
     AND A.BUY_PRICE = I_BOND_TRADE.BUY_PRICE;  
  
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
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5-1)거래내역 등록
  ----------------------------------------------------------------------------------------------------
  INSERT INTO BOND_TRADE VALUES I_BOND_TRADE;
  
  ----------------------------------------------------------------------------------------------------
  -- 5-2)잔고 등록
  ----------------------------------------------------------------------------------------------------
  INSERT INTO BOND_BALANCE VALUES T_BOND_BALANCE;
  
  
END;